from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Protocol
from urllib.request import Request, urlopen

import jwt
from sqlalchemy.ext.asyncio import AsyncSession

from kitchen_server.auth.service import AuthError, AuthService, VerifiedIdentityAssertion


class AppleKeyProvider(Protocol):
    async def keys(self, *, force_refresh: bool = False) -> dict[str, dict[str, object]]: ...


class AppleHttpKeyProvider:
    """按 key id 缓存 Apple 公钥, 未命中时强制刷新以处理公钥轮换。"""

    def __init__(self, url: str = "https://appleid.apple.com/auth/keys") -> None:
        self._url = url
        self._cached: dict[str, dict[str, object]] = {}

    async def keys(self, *, force_refresh: bool = False) -> dict[str, dict[str, object]]:
        if self._cached and not force_refresh:
            return self._cached
        payload = await asyncio.to_thread(self._fetch)
        keys = payload.get("keys")
        if not isinstance(keys, list):
            raise AuthError("invalid_credentials", 401)
        self._cached = {
            item["kid"]: item
            for item in keys
            if isinstance(item, dict) and isinstance(item.get("kid"), str)
        }
        return self._cached

    def _fetch(self) -> dict[str, object]:
        request = Request(self._url, headers={"Accept": "application/json"})
        with urlopen(request, timeout=5) as response:
            value = json.load(response)
        if not isinstance(value, dict):
            raise AuthError("invalid_credentials", 401)
        return value


class AppleAuthorizationStateStore(Protocol):
    async def issue(self, flow_id: str, nonce: str, *, now: datetime | None = None) -> None: ...

    async def consume(self, flow_id: str, nonce: str) -> bool: ...


class InMemoryAppleAuthorizationStateStore:
    """短期授权流程状态; 生产多副本部署应替换为共享 TTL 存储。"""

    def __init__(self, ttl: timedelta = timedelta(minutes=5)) -> None:
        self._ttl = ttl
        self._flows: dict[str, tuple[str, datetime]] = {}

    async def issue(self, flow_id: str, nonce: str, *, now: datetime | None = None) -> None:
        self._flows[flow_id] = (nonce, (now or datetime.now(UTC)) + self._ttl)

    async def consume(self, flow_id: str, nonce: str) -> bool:
        flow = self._flows.pop(flow_id, None)
        if flow is None:
            return False
        expected_nonce, expires_at = flow
        return expected_nonce == nonce and expires_at > datetime.now(UTC)


@dataclass(frozen=True)
class AppleCredential:
    """客户端提交的授权结果; 资料字段只作可选资料, 不作身份依据。"""

    identity_token: str
    authorization_code: str
    flow_id: str
    nonce: str
    email: str | None = None
    given_name: str | None = None
    family_name: str | None = None


@dataclass(frozen=True)
class AppleVerifierConfig:
    client_id: str
    issuer: str = "https://appleid.apple.com"


class AppleIdentityVerifier:
    """验证 Apple JWS 和一次性授权流程, 失败关闭且不产生账号副作用。"""

    def __init__(
        self,
        config: AppleVerifierConfig,
        key_provider: AppleKeyProvider,
        state_store: AppleAuthorizationStateStore,
    ) -> None:
        self._config = config
        self._key_provider = key_provider
        self._state_store = state_store

    async def verify(self, credential: AppleCredential) -> VerifiedIdentityAssertion:
        if not credential.identity_token or not credential.authorization_code:
            raise AuthError("invalid_credentials", 401)
        if not await self._state_store.consume(credential.flow_id, credential.nonce):
            raise AuthError("invalid_credentials", 401)

        try:
            header = jwt.get_unverified_header(credential.identity_token)
            key_id = header["kid"]
            algorithm = header["alg"]
        except (jwt.InvalidTokenError, KeyError, TypeError):
            raise AuthError("invalid_credentials", 401) from None
        if algorithm != "RS256" or not isinstance(key_id, str):
            raise AuthError("invalid_credentials", 401)

        keys = await self._key_provider.keys()
        jwk = keys.get(key_id)
        if jwk is None:
            keys = await self._key_provider.keys(force_refresh=True)
            jwk = keys.get(key_id)
        if jwk is None:
            raise AuthError("invalid_credentials", 401)

        try:
            claims = jwt.decode(
                credential.identity_token,
                jwt.PyJWK.from_dict(jwk).key,
                algorithms=["RS256"],
                audience=self._config.client_id,
                issuer=self._config.issuer,
                options={"require": ["sub", "iss", "aud", "exp", "iat", "nonce"]},
            )
        except (jwt.InvalidTokenError, TypeError, ValueError):
            raise AuthError("invalid_credentials", 401) from None
        if claims.get("nonce") != credential.nonce:
            raise AuthError("invalid_credentials", 401)
        subject = claims.get("sub")
        if not isinstance(subject, str) or not subject:
            raise AuthError("invalid_credentials", 401)

        return VerifiedIdentityAssertion(
            provider="apple",
            provider_subject=subject,
            issuer_audience_scope=f"{self._config.issuer}:{self._config.client_id}",
            email=_optional_string(credential.email),
            given_name=_optional_string(credential.given_name),
            family_name=_optional_string(credential.family_name),
        )


class AppleRevocationHandler:
    """处理 Apple 撤销通知或定期状态检查, 只撤销对应 Apple 身份。"""

    def __init__(self, auth_service: AuthService) -> None:
        self._auth_service = auth_service

    async def handle(
        self,
        session: AsyncSession,
        *,
        provider_subject: str,
        client_id: str,
        now: datetime | None = None,
    ) -> bool:
        return await self._auth_service.revoke_identity(
            session,
            VerifiedIdentityAssertion(
                provider="apple",
                provider_subject=provider_subject,
                issuer_audience_scope=f"https://appleid.apple.com:{client_id}",
            ),
            now=now,
        )


def _optional_string(value: str | None) -> str | None:
    value = value.strip() if value is not None else None
    return value or None
