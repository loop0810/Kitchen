from __future__ import annotations

import re
from uuid import uuid4

from starlette.datastructures import Headers, MutableHeaders
from starlette.responses import JSONResponse
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from kitchen_server.app.logging import SafeEventRecorder

_REQUEST_ID_PATTERN = re.compile(r"^[A-Za-z0-9_.-]{1,64}$")


def controlled_request_id(candidate: str | None) -> str:
    if candidate is not None and _REQUEST_ID_PATTERN.fullmatch(candidate):
        return candidate
    return str(uuid4())


class RequestIDMiddleware:
    def __init__(self, app: ASGIApp) -> None:
        self._app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self._app(scope, receive, send)
            return

        request_id = controlled_request_id(Headers(scope=scope).get("x-request-id"))
        scope.setdefault("state", {})["request_id"] = request_id

        async def send_with_request_id(message: Message) -> None:
            if message["type"] == "http.response.start":
                MutableHeaders(scope=message)["X-Request-ID"] = request_id
            await send(message)

        await self._app(scope, receive, send_with_request_id)


class SafeErrorMiddleware:
    def __init__(self, app: ASGIApp, recorder: SafeEventRecorder) -> None:
        self._app = app
        self._recorder = recorder

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        async def send_with_error_event(message: Message) -> None:
            if message["type"] == "http.response.start":
                status = int(message["status"])
                if status >= 400:
                    state = scope.get("state", {})
                    request_id = str(state.get("request_id", uuid4()))
                    self._recorder.request_failed(
                        request_id=request_id,
                        status=status,
                        error_category=_error_category(status),
                    )
            await send(message)

        try:
            await self._app(scope, receive, send_with_error_event)
        except Exception:
            state = scope.get("state", {})
            request_id = str(state.get("request_id", uuid4()))
            self._recorder.request_failed(
                request_id=request_id,
                status=500,
                error_category="internal_error",
            )
            response = JSONResponse(
                status_code=500,
                content={"detail": "internal_server_error"},
            )
            await response(scope, receive, send)


def _error_category(status: int) -> str:
    if status == 503:
        return "dependency_unavailable"
    if status < 500:
        return "client_error"
    return "server_error"
