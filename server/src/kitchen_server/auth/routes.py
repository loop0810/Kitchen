from __future__ import annotations

import hashlib
import json
from datetime import UTC, datetime, timedelta
from typing import Annotated, cast

from fastapi import APIRouter, Depends, Header, Request, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from kitchen_server.app.dependencies import get_database_session
from kitchen_server.auth.apple import (
    AppleAuthorizationStateStore,
    AppleCredential,
    AppleIdentityVerifier,
)
from kitchen_server.auth.models import DeviceSession, User
from kitchen_server.auth.service import AuthError, AuthService, verify_access_token
from kitchen_server.infrastructure.config import Settings

router = APIRouter(prefix="/v1/auth/apple", tags=["auth"])
account_router = APIRouter(prefix="/v1/auth", tags=["auth"])


class AppleFlowRequest(BaseModel):
    flow_id: str = Field(min_length=16, max_length=128, alias="flowId")
    nonce: str = Field(min_length=16, max_length=256)


class AppleExchangeRequest(AppleFlowRequest):
    identity_token: str = Field(min_length=16, alias="identityToken")
    authorization_code: str = Field(min_length=1, alias="authorizationCode")
    email: str | None = Field(default=None, max_length=320)
    given_name: str | None = Field(default=None, max_length=120)
    family_name: str | None = Field(default=None, max_length=120)


@router.post("/flow", status_code=status.HTTP_204_NO_CONTENT)
async def begin_apple_flow(request: Request, body: AppleFlowRequest) -> Response:
    store = cast(AppleAuthorizationStateStore, request.app.state.apple_state_store)
    await store.issue(body.flow_id, body.nonce)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/exchange", response_model=None)
async def exchange_apple(
    request: Request,
    body: AppleExchangeRequest,
    session: Annotated[AsyncSession, Depends(get_database_session)],
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
) -> dict[str, object] | JSONResponse:
    if idempotency_key != body.flow_id:
        raise AuthError("invalid_request", 400)
    request_hash = hashlib.sha256(
        json.dumps(body.model_dump(by_alias=True), sort_keys=True).encode()
    ).hexdigest()
    settings = cast(Settings, request.app.state.settings)
    service = AuthService(settings)
    existing = await service.get_idempotency_by_operation(
        session, "apple_exchange", body.flow_id, request_hash
    )
    if existing is not None:
        return JSONResponse(
            status_code=existing.response_status,
            content=json.loads(existing.response_json),
        )
    if settings.apple_client_id is None:
        raise AuthError("invalid_request", 503)
    verifier = cast(AppleIdentityVerifier, request.app.state.apple_verifier)
    assertion = await verifier.verify(
        AppleCredential(
            identity_token=body.identity_token,
            authorization_code=body.authorization_code,
            flow_id=body.flow_id,
            nonce=body.nonce,
            email=body.email,
            given_name=body.given_name,
            family_name=body.family_name,
        )
    )
    tokens = await service.authenticate(
        session,
        assertion,
        device_name="Apple 登录设备",
        idempotency_key=idempotency_key,
    )
    response_body: dict[str, object] = {
        "tokens": {
            "userId": tokens.user_id,
            "sessionId": tokens.session_id,
            "accessToken": tokens.access_token,
            "refreshToken": tokens.refresh_token,
            "accessExpiresAt": tokens.access_expires_at.isoformat(),
            "refreshExpiresAt": tokens.refresh_expires_at.isoformat(),
        }
    }
    await service.save_idempotency(
        session,
        user_id=tokens.user_id,
        operation="apple_exchange",
        key=body.flow_id,
        request_hash=request_hash,
        response_status=200,
        response_json=json.dumps(response_body, separators=(",", ":")),
    )
    await session.commit()
    return response_body


async def _current_user(
    authorization: str | None,
    session: AsyncSession,
    settings: Settings,
) -> tuple[str, dict[str, object]]:
    if authorization is None or not authorization.startswith("Bearer "):
        raise AuthError("invalid_session", 401)
    payload = verify_access_token(settings, authorization[7:])
    user_id = payload.get("sub")
    session_id = payload.get("sid")
    if not isinstance(user_id, str) or not isinstance(session_id, str):
        raise AuthError("invalid_session", 401)
    device_session = await session.get(DeviceSession, session_id)
    user = await session.get(User, user_id)
    if (
        device_session is None
        or device_session.user_id != user_id
        or device_session.status != "active"
        or user is None
        or user.status != "active"
    ):
        raise AuthError("invalid_session", 401)
    return user_id, payload


@account_router.get("/identities")
async def list_auth_identities(
    request: Request,
    session: Annotated[AsyncSession, Depends(get_database_session)],
    authorization: Annotated[str | None, Header()] = None,
) -> dict[str, list[dict[str, str | None]]]:
    settings = cast(Settings, request.app.state.settings)
    user_id, _ = await _current_user(authorization, session, settings)
    identities = await AuthService(settings).list_identities(session, user_id)
    return {
        "identities": [
            {
                "id": identity.identity_id,
                "provider": identity.provider,
                "status": identity.status,
                "email": identity.email,
            }
            for identity in identities
        ]
    }


@account_router.delete("/identities/{identity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unbind_auth_identity(
    identity_id: str,
    request: Request,
    session: Annotated[AsyncSession, Depends(get_database_session)],
    authorization: Annotated[str | None, Header()] = None,
) -> Response:
    settings = cast(Settings, request.app.state.settings)
    user_id, payload = await _current_user(authorization, session, settings)
    issued_at = payload.get("iat")
    recently_reauthenticated = isinstance(issued_at, int) and (
        datetime.now(UTC) - datetime.fromtimestamp(issued_at, UTC)
        <= timedelta(minutes=10)
    )
    await AuthService(settings).unbind_identity(
        session,
        user_id,
        identity_id,
        recently_reauthenticated=recently_reauthenticated,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
