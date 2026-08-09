from __future__ import annotations

import hashlib
import json
from typing import Annotated, cast

from fastapi import APIRouter, Depends, Header, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from kitchen_server.app.dependencies import get_database_session
from kitchen_server.auth.phone import (
    RiskContext,
    normalize_cn_mobile,
    phone_subject,
)
from kitchen_server.auth.service import (
    AuthError,
    AuthService,
    SessionTokens,
    VerifiedIdentityAssertion,
)
from kitchen_server.infrastructure.config import Settings

router = APIRouter(prefix="/v1/auth/phone", tags=["auth"])


class PhoneChallengeRequest(BaseModel):
    phone: str = Field(min_length=5, max_length=32)
    captcha_token: str = Field(min_length=1, max_length=2048, alias="captchaToken")
    installation_id: str = Field(min_length=8, max_length=128, alias="installationId")


class PhoneVerifyRequest(BaseModel):
    challenge_id: str = Field(min_length=16, max_length=128, alias="challengeId")
    code: str = Field(min_length=6, max_length=6)


@router.post("/challenge", response_model=None)
async def create_phone_challenge(
    request: Request,
    body: PhoneChallengeRequest,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
) -> dict[str, object] | JSONResponse:
    settings = cast(Settings, request.app.state.settings)
    if settings.phone_auth_mode != "mock":
        raise AuthError("sms_unavailable", 503)
    if idempotency_key is None or len(idempotency_key) < 16:
        raise AuthError("invalid_request", 400)
    normalized = normalize_cn_mobile(body.phone)
    runtime = request.app.state.phone_runtime
    request_hash = hashlib.sha256(
        json.dumps(body.model_dump(by_alias=True), sort_keys=True).encode()
    ).hexdigest()
    previous = runtime.idempotency.get(idempotency_key)
    if previous is not None:
        if previous[0] != request_hash:
            raise AuthError("idempotency_conflict", 409)
        return cast(dict[str, object], previous[1])
    captcha_ok = await runtime.captcha.verify_once(body.captcha_token, "sms_send")
    if not captcha_ok:
        raise AuthError("captcha_invalid", 400)
    ip = request.client.host if request.client is not None else "unknown"
    context = RiskContext(
        installation_id=body.installation_id,
        ip=ip,
        network=_network_prefix(ip),
        captcha_action="sms_send",
    )
    subject = phone_subject(normalized, settings.phone_otp_pepper.get_secret_value())
    await runtime.risk.reserve(subject, context)
    challenge, code = await runtime.otp.issue(
        normalized,
        code_override=settings.phone_mock_otp,
    )
    await runtime.sender.send(
        phone=normalized,
        code=code,
        intent_id=challenge.challenge_id,
    )
    response: dict[str, object] = {
        "challengeId": challenge.challenge_id,
        "retryAfterSeconds": 60,
    }
    runtime.idempotency[idempotency_key] = (request_hash, response)
    return response


@router.post("/verify", response_model=None)
async def verify_phone_challenge(
    request: Request,
    body: PhoneVerifyRequest,
    session: Annotated[AsyncSession, Depends(get_database_session)],
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
) -> dict[str, object] | JSONResponse:
    settings = cast(Settings, request.app.state.settings)
    if idempotency_key is None or len(idempotency_key) < 16:
        raise AuthError("invalid_request", 400)
    runtime = request.app.state.phone_runtime
    request_hash = hashlib.sha256(
        json.dumps(body.model_dump(by_alias=True), sort_keys=True).encode()
    ).hexdigest()
    previous = runtime.idempotency.get(idempotency_key)
    if previous is not None:
        if previous[0] != request_hash:
            raise AuthError("idempotency_conflict", 409)
        return cast(dict[str, object], previous[1])
    challenge = await runtime.otp.verify(body.challenge_id, body.code)
    assertion = VerifiedIdentityAssertion(
        provider="phone",
        provider_subject=challenge.phone_subject,
        issuer_audience_scope="phone:cn",
    )
    tokens = await AuthService(settings).authenticate(
        session,
        assertion,
        device_name="手机号登录设备",
        idempotency_key=idempotency_key,
    )
    response: dict[str, object] = {"tokens": _token_response(tokens)}
    runtime.idempotency[idempotency_key] = (request_hash, response)
    return response


def _network_prefix(ip: str) -> str:
    parts = ip.split(".")
    return ".".join(parts[:3]) + ".0/24" if len(parts) == 4 else ip


def _token_response(tokens: SessionTokens) -> dict[str, object]:
    return {
        "userId": tokens.user_id,
        "sessionId": tokens.session_id,
        "accessToken": tokens.access_token,
        "refreshToken": tokens.refresh_token,
        "accessExpiresAt": tokens.access_expires_at.isoformat(),
        "refreshExpiresAt": tokens.refresh_expires_at.isoformat(),
    }
