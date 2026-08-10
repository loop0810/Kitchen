from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response, status
from fastapi.responses import JSONResponse

from kitchen_server.app.logging import JsonSafeEventRecorder, SafeEventRecorder
from kitchen_server.app.middleware import RequestIDMiddleware, SafeErrorMiddleware
from kitchen_server.auth.apple import (
    AppleHttpKeyProvider,
    AppleIdentityVerifier,
    AppleVerifierConfig,
    InMemoryAppleAuthorizationStateStore,
)
from kitchen_server.auth.phone import (
    InMemoryCaptchaVerifier,
    InMemoryOtpChallengeStore,
    InMemoryRiskPreflight,
    OtpService,
    PhoneMockRuntime,
    RecordingSmsSender,
)
from kitchen_server.auth.phone_routes import router as phone_auth_router
from kitchen_server.auth.routes import account_router
from kitchen_server.auth.routes import router as apple_auth_router
from kitchen_server.auth.service import AuthError
from kitchen_server.domain.readiness import RuntimeReadinessChecker
from kitchen_server.infrastructure.config import Settings, load_settings
from kitchen_server.infrastructure.database import Database

_logger = logging.getLogger("kitchen_server")


def create_app(
    settings: Settings | None = None,
    *,
    readiness_checker: RuntimeReadinessChecker | None = None,
    event_recorder: SafeEventRecorder | None = None,
) -> FastAPI:
    runtime_settings = settings or load_settings()
    database = Database(runtime_settings) if readiness_checker is None else None
    checker = readiness_checker or database
    if checker is None:
        raise RuntimeError("runtime_readiness_checker_missing")

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        app.state.settings = runtime_settings
        app.state.database = database
        app.state.phone_runtime = PhoneMockRuntime(
            otp=OtpService(
                InMemoryOtpChallengeStore(),
                pepper=runtime_settings.phone_otp_pepper.get_secret_value(),
            ),
            captcha=InMemoryCaptchaVerifier(
                runtime_settings.phone_mock_captcha_token.get_secret_value(),
                reusable=True,
            ),
            risk=InMemoryRiskPreflight(
                max_total=runtime_settings.phone_daily_send_limit,
                cost_limit=runtime_settings.phone_daily_budget_units,
            ),
            sender=RecordingSmsSender(),
            idempotency={},
        )
        state_store = InMemoryAppleAuthorizationStateStore()
        app.state.apple_state_store = state_store
        app.state.apple_verifier = AppleIdentityVerifier(
            AppleVerifierConfig(
                client_id=runtime_settings.apple_client_id or "",
                issuer=runtime_settings.apple_issuer,
            ),
            AppleHttpKeyProvider(),
            state_store,
        )
        yield
        if database is not None:
            await database.dispose()

    app = FastAPI(
        title="Kitchen Server",
        docs_url=None,
        redoc_url=None,
        openapi_url=None,
        lifespan=lifespan,
    )
    recorder = event_recorder or JsonSafeEventRecorder()
    app.add_middleware(SafeErrorMiddleware, recorder=recorder)
    app.add_middleware(RequestIDMiddleware)
    app.include_router(apple_auth_router)
    app.include_router(account_router)
    app.include_router(phone_auth_router)

    @app.exception_handler(AuthError)
    async def auth_error(request: Request, error: AuthError) -> JSONResponse:
        request_id = str(request.scope.get("state", {}).get("request_id", ""))
        return JSONResponse(
            status_code=error.status_code,
            content=error.envelope(request_id),
        )

    @app.get("/health/live")
    async def live() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/health/ready")
    async def ready(response: Response) -> dict[str, str]:
        try:
            is_ready = await checker.is_ready()
        except Exception as error:
            # The probe stays a plain 503 for callers, but an unexpected readiness
            # failure must not disappear; only the exception type is recorded.
            _logger.error(
                "readiness_check_failed",
                extra={"error_category": type(error).__name__},
            )
            is_ready = False
        if not is_ready:
            response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
            return {"status": "unavailable"}
        return {"status": "ok"}

    return app
