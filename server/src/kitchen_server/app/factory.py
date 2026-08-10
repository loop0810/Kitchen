from __future__ import annotations

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


def create_app(
    settings: Settings | None = None,
    *,
    readiness_checker: RuntimeReadinessChecker | None = None,
    event_recorder: SafeEventRecorder | None = None,
) -> FastAPI:
    # 工厂负责“组装”运行时依赖，路由只从 app.state 或 Depends 获取它们。
    # 测试可以注入 readiness_checker/event_recorder，从而不必启动真实数据库或日志系统。
    runtime_settings = settings or load_settings()
    database = Database(runtime_settings) if readiness_checker is None else None
    checker = readiness_checker or database
    if checker is None:
        raise RuntimeError("runtime_readiness_checker_missing")

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        # lifespan 是应用级依赖的生命周期边界：启动时创建，退出时释放数据库连接池。
        # 认证适配器目前使用内存替身，明确隔离了本地/测试能力与生产供应商。
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
        # live 只回答进程是否活着，不检查数据库；否则数据库短暂故障会导致
        # 容器被错误重启，掩盖真正的依赖故障。
        return {"status": "ok"}

    @app.get("/health/ready")
    async def ready(response: Response) -> dict[str, str]:
        # ready 才检查数据库等运行依赖，供负载均衡器决定是否把流量交给实例。
        try:
            is_ready = await checker.is_ready()
        except Exception:
            is_ready = False
        if not is_ready:
            response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
            return {"status": "unavailable"}
        return {"status": "ok"}

    return app
