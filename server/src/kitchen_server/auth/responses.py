from __future__ import annotations

import hashlib
import json

from pydantic import BaseModel

from kitchen_server.auth.service import AuthError, SessionTokens


def request_fingerprint(body: BaseModel) -> str:
    """请求体的稳定指纹, 用于判断同一幂等键是否重复提交了相同请求。"""
    return hashlib.sha256(
        json.dumps(body.model_dump(by_alias=True), sort_keys=True).encode()
    ).hexdigest()


def token_response(tokens: SessionTokens) -> dict[str, object]:
    """会话令牌的跨端契约表示; 字段名由 docs/contracts 约定, 服务端不额外记录令牌值。"""
    return {
        "userId": tokens.user_id,
        "sessionId": tokens.session_id,
        "accessToken": tokens.access_token,
        "refreshToken": tokens.refresh_token,
        "accessExpiresAt": tokens.access_expires_at.isoformat(),
        "refreshExpiresAt": tokens.refresh_expires_at.isoformat(),
    }


def replayed_response(
    store: dict[str, tuple[str, dict[str, object]]],
    idempotency_key: str,
    request_hash: str,
) -> dict[str, object] | None:
    """返回同一幂等键已记录的响应; 请求体不一致时按契约报冲突。"""
    previous = store.get(idempotency_key)
    if previous is None:
        return None
    if previous[0] != request_hash:
        raise AuthError("idempotency_conflict", 409)
    return previous[1]
