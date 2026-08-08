from __future__ import annotations

import base64
import hashlib
import hmac
import json
import secrets
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import cast
from uuid import uuid4

from sqlalchemy import func as sa_func
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from kitchen_server.auth.models import (
    AuthIdentity,
    DeviceSession,
    IdempotencyRecord,
    RefreshTokenFamily,
    User,
)
from kitchen_server.infrastructure.config import Settings


@dataclass(frozen=True)
class VerifiedIdentityAssertion:
    """第三方适配器验证后交给 Auth 模块的最小身份断言。"""

    provider: str
    provider_subject: str
    issuer_audience_scope: str
    email: str | None = None
    given_name: str | None = None
    family_name: str | None = None


@dataclass(frozen=True)
class SessionTokens:
    """一次认证或刷新返回的短期访问凭证和刷新凭证。"""

    user_id: str
    session_id: str
    access_token: str
    refresh_token: str
    access_expires_at: datetime
    refresh_expires_at: datetime


@dataclass(frozen=True)
class DeviceSessionSummary:
    """供账号管理页面展示的非敏感设备会话信息。"""

    session_id: str
    device_name: str
    created_at: datetime
    last_used_at: datetime
    expires_at: datetime
    revoked_at: datetime | None


@dataclass(frozen=True)
class AuthIdentitySummary:
    """供账号设置展示的认证身份摘要, 不暴露 provider subject。"""

    identity_id: str
    provider: str
    status: str
    email: str | None


@dataclass(frozen=True)
class IdempotentResponse:
    """幂等记录的稳定结果; 响应正文由 HTTP 层序列化。"""

    status_code: int
    response_json: str


class AuthError(Exception):
    def __init__(self, code: str, status_code: int = 400) -> None:
        super().__init__(code)
        self.code = code
        self.status_code = status_code

    def envelope(self, request_id: str) -> dict[str, dict[str, str]]:
        """统一错误形状只返回稳定代码, 不返回账号或底层异常细节。"""
        messages = {
            "invalid_session": "会话已失效",
            "identity_conflict": "身份无法绑定",
            "recent_auth_required": "请先完成近期重新认证",
            "session_replay_detected": "会话已失效",
            "idempotency_conflict": "请求幂等键与原请求不一致",
            "account_deletion_in_progress": "账号正在删除处理中",
            "identity_revoked": "登录身份已撤销",
        }
        return {
            "error": {
                "code": self.code,
                "message": messages.get(self.code, "请求无法完成"),
                "requestId": request_id,
            }
        }


class SecurityAuditRecorder:
    """认证安全事件端口, 事件不得包含令牌、身份 subject 或请求正文。"""

    def security_event(self, *, event: str, user_id: str | None, session_id: str | None) -> None:
        raise NotImplementedError


class NullSecurityAuditRecorder(SecurityAuditRecorder):
    def security_event(self, *, event: str, user_id: str | None, session_id: str | None) -> None:
        return


class AuthService:
    def __init__(
        self,
        settings: Settings,
        *,
        audit_recorder: SecurityAuditRecorder | None = None,
    ) -> None:
        self._settings = settings
        self._audit = audit_recorder or NullSecurityAuditRecorder()

    async def authenticate(
        self,
        session: AsyncSession,
        assertion: VerifiedIdentityAssertion,
        *,
        device_name: str,
        idempotency_key: str | None = None,
        now: datetime | None = None,
    ) -> SessionTokens:
        current = now or datetime.now(UTC)
        identity = await session.scalar(
            select(AuthIdentity).where(
                AuthIdentity.provider == assertion.provider,
                AuthIdentity.provider_subject == assertion.provider_subject,
                AuthIdentity.issuer_audience_scope == assertion.issuer_audience_scope,
            )
        )
        if identity is None:
            user = User(
                id=str(uuid4()),
                status="active",
                created_at=current,
            )
            identity = AuthIdentity(
                id=str(uuid4()),
                user=user,
                provider=assertion.provider,
                provider_subject=assertion.provider_subject,
                issuer_audience_scope=assertion.issuer_audience_scope,
                email=assertion.email,
                given_name=assertion.given_name,
                family_name=assertion.family_name,
                created_at=current,
                last_authenticated_at=current,
            )
            try:
                async with session.begin_nested():
                    session.add(user)
                    session.add(identity)
                    await session.flush()
            except IntegrityError:
                identity = await session.scalar(
                    select(AuthIdentity).where(
                        AuthIdentity.provider == assertion.provider,
                        AuthIdentity.provider_subject == assertion.provider_subject,
                        AuthIdentity.issuer_audience_scope == assertion.issuer_audience_scope,
                    )
                )
                if identity is None:
                    raise
                existing_user = await session.get(User, identity.user_id)
                if existing_user is None:
                    raise AuthError("invalid_identity", 401) from None
                user = existing_user
        else:
            existing_user = await session.get(User, identity.user_id)
            if existing_user is None:
                raise AuthError("invalid_identity", 401)
            if existing_user.status != "active":
                raise AuthError("account_deletion_in_progress", 409)
            if identity.status != "active":
                raise AuthError("identity_revoked", 401)
            identity.last_authenticated_at = current
            if identity.email is None:
                identity.email = assertion.email
            if identity.given_name is None:
                identity.given_name = assertion.given_name
            if identity.family_name is None:
                identity.family_name = assertion.family_name
            user = existing_user

        tokens = await self._create_session(session, user, device_name=device_name, now=current)
        await session.commit()
        return tokens

    async def revoke_identity(
        self,
        session: AsyncSession,
        assertion: VerifiedIdentityAssertion,
        *,
        now: datetime | None = None,
    ) -> bool:
        """标记单个外部身份撤销, 不影响账号绑定的其他身份。"""
        identity = await session.scalar(
            select(AuthIdentity).where(
                AuthIdentity.provider == assertion.provider,
                AuthIdentity.provider_subject == assertion.provider_subject,
                AuthIdentity.issuer_audience_scope == assertion.issuer_audience_scope,
            )
        )
        if identity is None:
            return False
        identity.status = "revoked"
        identity.revoked_at = now or datetime.now(UTC)
        await session.commit()
        return True

    async def bind_identity(
        self,
        session: AsyncSession,
        user_id: str,
        assertion: VerifiedIdentityAssertion,
        *,
        recently_reauthenticated: bool,
        now: datetime | None = None,
    ) -> AuthIdentity:
        """绑定只接受近期重新认证, 且冲突时不暴露占用账号。"""
        if not recently_reauthenticated:
            raise AuthError("recent_auth_required", 401)
        user = await session.get(User, user_id)
        if user is None or user.status != "active":
            raise AuthError("invalid_session", 401)
        existing = await session.scalar(
            select(AuthIdentity).where(
                AuthIdentity.provider == assertion.provider,
                AuthIdentity.provider_subject == assertion.provider_subject,
                AuthIdentity.issuer_audience_scope == assertion.issuer_audience_scope,
            )
        )
        if existing is not None:
            if existing.user_id == user_id:
                return existing
            self._audit.security_event(event="identity_conflict", user_id=user_id, session_id=None)
            raise AuthError("identity_conflict", 409)
        current = now or datetime.now(UTC)
        identity = AuthIdentity(
            id=str(uuid4()),
            user_id=user_id,
            provider=assertion.provider,
            provider_subject=assertion.provider_subject,
            issuer_audience_scope=assertion.issuer_audience_scope,
            created_at=current,
            last_authenticated_at=current,
        )
        session.add(identity)
        try:
            await session.flush()
        except IntegrityError:
            self._audit.security_event(event="identity_conflict", user_id=user_id, session_id=None)
            raise AuthError("identity_conflict", 409) from None
        await session.commit()
        return identity

    async def unbind_identity(
        self,
        session: AsyncSession,
        user_id: str,
        identity_id: str,
        *,
        recently_reauthenticated: bool,
    ) -> None:
        if not recently_reauthenticated:
            raise AuthError("recent_auth_required", 401)
        identity = await session.get(AuthIdentity, identity_id)
        if identity is None or identity.user_id != user_id:
            raise AuthError("invalid_request", 400)
        count = await session.scalar(
            select(sa_func.count(AuthIdentity.id)).where(AuthIdentity.user_id == user_id)
        )
        if count is not None and count <= 1:
            raise AuthError("invalid_request", 400)
        await session.delete(identity)
        await session.commit()

    async def list_identities(
        self, session: AsyncSession, user_id: str
    ) -> list[AuthIdentitySummary]:
        rows = await session.scalars(
            select(AuthIdentity)
            .where(AuthIdentity.user_id == user_id)
            .order_by(AuthIdentity.created_at.asc())
        )
        return [
            AuthIdentitySummary(
                identity_id=row.id,
                provider=row.provider,
                status=row.status,
                email=row.email,
            )
            for row in rows
        ]

    async def list_sessions(
        self, session: AsyncSession, user_id: str
    ) -> list[DeviceSessionSummary]:
        rows = await session.scalars(
            select(DeviceSession)
            .where(DeviceSession.user_id == user_id)
            .order_by(DeviceSession.last_used_at.desc())
        )
        return [
            DeviceSessionSummary(
                session_id=row.id,
                device_name=row.device_name,
                created_at=row.created_at,
                last_used_at=row.last_used_at,
                expires_at=row.expires_at,
                revoked_at=row.revoked_at,
            )
            for row in rows
        ]

    async def request_account_deletion(
        self,
        session: AsyncSession,
        user_id: str,
        *,
        recently_reauthenticated: bool,
        now: datetime | None = None,
    ) -> None:
        if not recently_reauthenticated:
            raise AuthError("recent_auth_required", 401)
        user = await session.get(User, user_id)
        if user is None:
            raise AuthError("invalid_session", 401)
        if user.status == "deleted":
            return
        current = now or datetime.now(UTC)
        user.status = "deletion_pending"
        user.deletion_requested_at = current
        await self._revoke_all_in_transaction(session, user_id, current)
        await session.commit()
        self._audit.security_event(
            event="account_deletion_requested", user_id=user_id, session_id=None
        )

    async def run_account_cleanup(
        self, session: AsyncSession, user_id: str, *, now: datetime | None = None
    ) -> None:
        """清理任务可安全重试; 外部业务表应在此事务边界内删除。"""
        user = await session.get(User, user_id)
        if user is None or user.status == "deleted":
            return
        if user.status != "deletion_pending":
            raise AuthError("invalid_request", 400)
        user.status = "deleted"
        user.deletion_completed_at = now or datetime.now(UTC)
        await session.commit()

    async def refresh(
        self,
        session: AsyncSession,
        refresh_token: str,
        *,
        now: datetime | None = None,
    ) -> SessionTokens:
        current = now or datetime.now(UTC)
        digest = _digest(refresh_token)
        family = await session.scalar(
            select(RefreshTokenFamily)
            .options(joinedload(RefreshTokenFamily.session))
            .where(RefreshTokenFamily.current_token_digest == digest)
        )
        if family is None:
            replayed = await session.scalar(
                select(RefreshTokenFamily).where(RefreshTokenFamily.previous_token_digest == digest)
            )
            if replayed is not None:
                await self._revoke_family(session, replayed, current)
                await session.commit()
                self._audit.security_event(
                    event="refresh_replay_detected",
                    user_id=None,
                    session_id=replayed.session_id,
                )
                raise AuthError("session_replay_detected", 401)
            raise AuthError("invalid_session", 401)
        if (
            family.status != "active"
            or family.expires_at <= current
            or family.session is None
            or family.session.status != "active"
        ):
            raise AuthError("invalid_session", 401)

        device_session = family.session
        user = await session.get(User, device_session.user_id)
        if user is None or user.status != "active":
            raise AuthError("invalid_session", 401)
        next_refresh = _new_refresh_token()
        family.previous_token_digest = family.current_token_digest
        family.current_token_digest = _digest(next_refresh)
        family.rotation += 1
        device_session.last_used_at = current
        await session.commit()
        return _tokens(
            self._settings,
            user.id,
            device_session.id,
            next_refresh,
            current,
            family.expires_at,
        )

    async def revoke_current(self, session: AsyncSession, session_id: str) -> None:
        device_session = await session.get(DeviceSession, session_id)
        if device_session is None:
            return
        device_session.status = "revoked"
        device_session.revoked_at = datetime.now(UTC)
        family = await session.scalar(
            select(RefreshTokenFamily).where(RefreshTokenFamily.session_id == session_id)
        )
        if family is not None:
            await self._revoke_family(session, family, device_session.revoked_at)
        await session.commit()

    async def revoke_all(self, session: AsyncSession, user_id: str) -> None:
        now = datetime.now(UTC)
        await self._revoke_all_in_transaction(session, user_id, now)
        await session.commit()

    async def _revoke_all_in_transaction(
        self, session: AsyncSession, user_id: str, now: datetime
    ) -> None:
        sessions = list(
            (
                await session.scalars(select(DeviceSession).where(DeviceSession.user_id == user_id))
            ).all()
        )
        for device_session in sessions:
            device_session.status = "revoked"
            device_session.revoked_at = now
        families = list(
            (
                await session.scalars(
                    select(RefreshTokenFamily)
                    .join(DeviceSession)
                    .where(DeviceSession.user_id == user_id)
                )
            ).all()
        )
        for family in families:
            family.status = "revoked"
            family.revoked_at = now

    async def get_idempotency(
        self,
        session: AsyncSession,
        user_id: str | None,
        operation: str,
        key: str,
        request_hash: str,
    ) -> IdempotencyRecord | None:
        record = await session.scalar(
            select(IdempotencyRecord).where(
                IdempotencyRecord.user_id == user_id,
                IdempotencyRecord.operation == operation,
                IdempotencyRecord.idempotency_key == key,
            )
        )
        if record is not None and record.request_hash != request_hash:
            raise AuthError("idempotency_conflict", 409)
        return record

    async def get_idempotency_by_operation(
        self,
        session: AsyncSession,
        operation: str,
        key: str,
        request_hash: str,
    ) -> IdempotencyRecord | None:
        """认证首请求尚未解析出 userId 时, 按操作和幂等键查找原结果。"""
        record = await session.scalar(
            select(IdempotencyRecord).where(
                IdempotencyRecord.operation == operation,
                IdempotencyRecord.idempotency_key == key,
            )
        )
        if record is not None and record.request_hash != request_hash:
            raise AuthError("idempotency_conflict", 409)
        return record

    async def save_idempotency(
        self,
        session: AsyncSession,
        *,
        user_id: str | None,
        operation: str,
        key: str,
        request_hash: str,
        response_status: int,
        response_json: str,
        now: datetime | None = None,
    ) -> IdempotencyRecord:
        """调用方在副作用事务中写入结果, 重试时通过 get_idempotency 复用。"""
        record = IdempotencyRecord(
            id=str(uuid4()),
            user_id=user_id,
            operation=operation,
            idempotency_key=key,
            request_hash=request_hash,
            response_status=response_status,
            response_json=response_json,
            created_at=now or datetime.now(UTC),
        )
        session.add(record)
        try:
            await session.flush()
        except IntegrityError:
            raise AuthError("idempotency_conflict", 409) from None
        return record

    async def _revoke_family(
        self, session: AsyncSession, family: RefreshTokenFamily, now: datetime
    ) -> None:
        family.status = "revoked"
        family.revoked_at = now
        device_session = await session.get(DeviceSession, family.session_id)
        if device_session is not None:
            device_session.status = "revoked"
            device_session.revoked_at = now

    async def _create_session(
        self,
        session: AsyncSession,
        user: User,
        *,
        device_name: str,
        now: datetime,
    ) -> SessionTokens:
        session_id = str(uuid4())
        refresh_expires_at = now + timedelta(seconds=self._settings.refresh_token_ttl_seconds)
        refresh_token = _new_refresh_token()
        device_session = DeviceSession(
            id=session_id,
            user=user,
            device_name=device_name[:120] or "未命名设备",
            status="active",
            created_at=now,
            last_used_at=now,
            expires_at=refresh_expires_at,
        )
        family = RefreshTokenFamily(
            id=str(uuid4()),
            session=device_session,
            current_token_digest=_digest(refresh_token),
            rotation=0,
            status="active",
            created_at=now,
            expires_at=refresh_expires_at,
        )
        session.add(device_session)
        session.add(family)
        await session.flush()
        return _tokens(self._settings, user.id, session_id, refresh_token, now, refresh_expires_at)


def _new_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def _identity_request_hash(assertion: VerifiedIdentityAssertion, device_name: str) -> str:
    value = "|".join(
        (
            assertion.provider,
            assertion.provider_subject,
            assertion.issuer_audience_scope,
            device_name,
        )
    )
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _digest(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _tokens(
    settings: Settings,
    user_id: str,
    session_id: str,
    refresh_token: str,
    now: datetime,
    refresh_expires_at: datetime,
) -> SessionTokens:
    access_expires_at = now + timedelta(seconds=settings.access_token_ttl_seconds)
    payload = {
        "sub": user_id,
        "sid": session_id,
        "iat": int(now.timestamp()),
        "exp": int(access_expires_at.timestamp()),
        "tokenType": "access",
    }
    encoded = _encode_json(payload)
    signature = hmac.new(
        settings.auth_signing_secret.get_secret_value().encode(), encoded.encode(), hashlib.sha256
    ).hexdigest()
    return SessionTokens(
        user_id=user_id,
        session_id=session_id,
        access_token=f"{encoded}.{signature}",
        refresh_token=refresh_token,
        access_expires_at=access_expires_at,
        refresh_expires_at=refresh_expires_at,
    )


def verify_access_token(
    settings: Settings, token: str, *, now: datetime | None = None
) -> dict[str, object]:
    try:
        encoded, signature = token.split(".", 1)
        expected = hmac.new(
            settings.auth_signing_secret.get_secret_value().encode(),
            encoded.encode(),
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(signature, expected):
            raise AuthError("invalid_session", 401)
        payload = cast(dict[str, object], json.loads(_decode_json(encoded)))
        current = int((now or datetime.now(UTC)).timestamp())
        if payload.get("tokenType") != "access" or int(cast(int, payload["exp"])) <= current:
            raise AuthError("invalid_session", 401)
        return payload
    except (AuthError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        if isinstance(error, AuthError):
            raise
        raise AuthError("invalid_session", 401) from None


def _encode_json(value: dict[str, object]) -> str:
    raw = json.dumps(value, separators=(",", ":"), sort_keys=True).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _decode_json(value: str) -> str:
    padding = "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(value + padding).decode()
