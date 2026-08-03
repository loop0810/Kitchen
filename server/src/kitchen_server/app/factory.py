from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Response, status

from kitchen_server.app.logging import JsonSafeEventRecorder, SafeEventRecorder
from kitchen_server.app.middleware import RequestIDMiddleware, SafeErrorMiddleware
from kitchen_server.domain.readiness import RuntimeReadinessChecker
from kitchen_server.infrastructure.config import Settings, load_settings
from kitchen_server.infrastructure.database import Database


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

    @app.get("/health/live")
    async def live() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/health/ready")
    async def ready(response: Response) -> dict[str, str]:
        try:
            is_ready = await checker.is_ready()
        except Exception:
            is_ready = False
        if not is_ready:
            response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
            return {"status": "unavailable"}
        return {"status": "ok"}

    return app
