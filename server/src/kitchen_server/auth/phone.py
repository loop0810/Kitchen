from __future__ import annotations

import asyncio
import hashlib
import hmac
import re
import secrets
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Protocol

from kitchen_server.auth.service import AuthError

_CN_MOBILE = re.compile(r"^1[3-9]\d{9}$")


def normalize_cn_mobile(value: str) -> str:
    """只接受中国大陆移动号码, 返回统一的 E.164 形式。"""
    compact = re.sub(r"[\s()-]", "", value)
    if compact.startswith("0086"):
        compact = compact[4:]
    elif compact.startswith("+86"):
        compact = compact[3:]
    if not _CN_MOBILE.fullmatch(compact):
        raise AuthError("phone_invalid", 400)
    return f"+86{compact}"


def mask_cn_mobile(phone: str) -> str:
    """仅用于安全事件的局部脱敏, 不返回完整号码。"""
    return f"+86****{phone[-4:]}"


def phone_subject(phone: str, pepper: str) -> str:
    return hmac.new(pepper.encode(), phone.encode(), hashlib.sha256).hexdigest()


@dataclass(frozen=True)
class OtpChallenge:
    """可持久化的验证码挑战, 只保存摘要和计数。"""

    challenge_id: str
    phone_subject: str
    otp_digest: str
    expires_at: datetime
    attempts: int = 0
    status: str = "active"


@dataclass(frozen=True)
class SmsSendIntent:
    """一次供应商调用的预算和幂等关联。"""

    intent_id: str
    challenge_id: str
    phone_subject: str
    cost_units: int
    status: str = "reserved"


@dataclass(frozen=True)
class RiskContext:
    installation_id: str
    ip: str
    network: str
    captcha_action: str


class CaptchaVerifier(Protocol):
    async def verify_once(self, token: str, action: str) -> bool: ...


class SmsSender(Protocol):
    async def send(self, *, phone: str, code: str, intent_id: str) -> str: ...


class RiskPreflight(Protocol):
    async def reserve(self, phone_subject: str, context: RiskContext) -> None: ...


class OtpChallengeStore(Protocol):
    async def invalidate_phone(self, phone_subject: str) -> None: ...

    async def create(self, challenge: OtpChallenge) -> None: ...

    async def get(self, challenge_id: str) -> OtpChallenge | None: ...

    async def replace(self, challenge: OtpChallenge) -> None: ...


class InMemoryOtpChallengeStore:
    """只用于单元测试和本地开发; 生产实现必须使用 PostgreSQL。"""

    def __init__(self) -> None:
        self._items: dict[str, OtpChallenge] = {}

    async def create(self, challenge: OtpChallenge) -> None:
        self._items[challenge.challenge_id] = challenge

    async def invalidate_phone(self, phone_subject: str) -> None:
        for challenge_id, challenge in tuple(self._items.items()):
            if challenge.phone_subject == phone_subject and challenge.status == "active":
                self._items[challenge_id] = OtpChallenge(
                    challenge_id=challenge.challenge_id,
                    phone_subject=challenge.phone_subject,
                    otp_digest=challenge.otp_digest,
                    expires_at=challenge.expires_at,
                    attempts=challenge.attempts,
                    status="superseded",
                )

    async def get(self, challenge_id: str) -> OtpChallenge | None:
        return self._items.get(challenge_id)

    async def replace(self, challenge: OtpChallenge) -> None:
        self._items[challenge.challenge_id] = challenge


class OtpService:
    def __init__(
        self,
        store: OtpChallengeStore,
        *,
        pepper: str,
        ttl_seconds: int = 300,
        max_attempts: int = 5,
    ) -> None:
        self._store = store
        self._pepper = pepper
        self._ttl_seconds = ttl_seconds
        self._max_attempts = max_attempts

    async def issue(
        self,
        phone: str,
        *,
        now: datetime | None = None,
        code_override: str | None = None,
    ) -> tuple[OtpChallenge, str]:
        normalized = normalize_cn_mobile(phone)
        code = code_override or f"{secrets.randbelow(1_000_000):06d}"
        if not re.fullmatch(r"\d{6}", code):
            raise ValueError("otp_override_must_be_six_digits")
        current = now or datetime.now(UTC)
        subject = phone_subject(normalized, self._pepper)
        await self._store.invalidate_phone(subject)
        challenge = OtpChallenge(
            challenge_id=secrets.token_urlsafe(24),
            phone_subject=subject,
            otp_digest=self._digest(code),
            expires_at=current + timedelta(seconds=self._ttl_seconds),
        )
        await self._store.create(challenge)
        return challenge, code

    async def verify(
        self, challenge_id: str, code: str, *, now: datetime | None = None
    ) -> OtpChallenge:
        challenge = await self._store.get(challenge_id)
        current = now or datetime.now(UTC)
        if (
            challenge is None
            or challenge.status != "active"
            or challenge.expires_at <= current
            or challenge.attempts >= self._max_attempts
        ):
            raise AuthError("otp_invalid", 401)
        if not hmac.compare_digest(challenge.otp_digest, self._digest(code)):
            updated = OtpChallenge(
                challenge_id=challenge.challenge_id,
                phone_subject=challenge.phone_subject,
                otp_digest=challenge.otp_digest,
                expires_at=challenge.expires_at,
                attempts=challenge.attempts + 1,
                status="locked" if challenge.attempts + 1 >= self._max_attempts else "active",
            )
            await self._store.replace(updated)
            raise AuthError("otp_invalid", 401)
        used = OtpChallenge(
            challenge_id=challenge.challenge_id,
            phone_subject=challenge.phone_subject,
            otp_digest=challenge.otp_digest,
            expires_at=challenge.expires_at,
            attempts=challenge.attempts,
            status="used",
        )
        await self._store.replace(used)
        return used

    def _digest(self, code: str) -> str:
        return hmac.new(self._pepper.encode(), code.encode(), hashlib.sha256).hexdigest()


class InMemoryRiskPreflight:
    """测试用原子预检替身, 用同一锁保护多维窗口和预算。"""

    def __init__(
        self,
        *,
        max_total: int = 5,
        cost_limit: int = 5,
        max_per_dimension: int = 3,
    ) -> None:
        self._max_total = max_total
        self._cost_limit = cost_limit
        self._max_per_dimension = max_per_dimension
        self._total = 0
        self._cost = 0
        self._counts: dict[tuple[str, str], int] = {}
        self._lock = asyncio.Lock()

    async def reserve(self, phone_subject: str, context: RiskContext) -> None:
        async with self._lock:
            dimensions = (
                ("phone", phone_subject),
                ("installation", context.installation_id),
                ("ip", context.ip),
                ("network", context.network),
            )
            if self._total >= self._max_total or any(
                self._counts.get(dimension, 0) >= self._max_per_dimension
                for dimension in dimensions
            ):
                raise AuthError("sms_rate_limited", 429)
            if self._cost + 1 > self._cost_limit:
                raise AuthError("sms_budget_exhausted", 503)
            for dimension in dimensions:
                self._counts[dimension] = self._counts.get(dimension, 0) + 1
            self._total += 1
            self._cost += 1


class InMemoryCaptchaVerifier:
    """模拟 CAPTCHA 校验器; 可选复用固定 token 以支持本地重复登录。"""

    def __init__(self, expected_token: str, *, reusable: bool = False) -> None:
        self._expected_token = expected_token
        self._reusable = reusable
        self._used: set[str] = set()

    async def verify_once(self, token: str, action: str) -> bool:
        if action != "sms_send" or token != self._expected_token:
            return False
        if not self._reusable and token in self._used:
            return False
        self._used.add(token)
        return True


class RecordingSmsSender:
    """测试替身只记录脱敏调用, 生产实现不能记录 code 或完整号码。"""

    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []

    async def send(self, *, phone: str, code: str, intent_id: str) -> str:
        self.calls.append((mask_cn_mobile(phone), intent_id))
        return "accepted"


class BoundedIdempotencyCache:
    """进程内幂等结果缓存; 带 TTL 和容量上限, 避免匿名请求撑爆内存并长期留存令牌。"""

    def __init__(self, *, ttl_seconds: int = 300, max_entries: int = 10_000) -> None:
        self._ttl_seconds = ttl_seconds
        self._max_entries = max_entries
        self._items: dict[str, tuple[str, dict[str, object], datetime]] = {}

    def get(self, key: str) -> tuple[str, dict[str, object]] | None:
        item = self._items.get(key)
        if item is None:
            return None
        request_hash, response, expires_at = item
        if expires_at <= datetime.now(UTC):
            del self._items[key]
            return None
        return request_hash, response

    def __setitem__(self, key: str, value: tuple[str, dict[str, object]]) -> None:
        now = datetime.now(UTC)
        self._purge(now)
        request_hash, response = value
        self._items[key] = (request_hash, response, now + timedelta(seconds=self._ttl_seconds))

    def _purge(self, now: datetime) -> None:
        expired = [key for key, item in self._items.items() if item[2] <= now]
        for key in expired:
            del self._items[key]
        overflow = len(self._items) - self._max_entries + 1
        if overflow <= 0:
            return
        oldest = sorted(self._items.items(), key=lambda item: item[1][2])[:overflow]
        for key, _ in oldest:
            del self._items[key]


@dataclass
class PhoneMockRuntime:
    """模拟登录运行时依赖, 通过应用状态注入路由且不触达外部短信接口。"""

    otp: OtpService
    captcha: InMemoryCaptchaVerifier
    risk: InMemoryRiskPreflight
    sender: RecordingSmsSender
    idempotency: BoundedIdempotencyCache


def new_intent(challenge: OtpChallenge) -> SmsSendIntent:
    return SmsSendIntent(
        intent_id=secrets.token_urlsafe(18),
        challenge_id=challenge.challenge_id,
        phone_subject=challenge.phone_subject,
        cost_units=1,
    )
