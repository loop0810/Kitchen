from __future__ import annotations

import io
import json
import logging
from dataclasses import dataclass, field

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from kitchen_server.app.factory import create_app
from kitchen_server.app.logging import JsonSafeEventRecorder, SafeJsonFormatter
from kitchen_server.infrastructure.config import Settings


@dataclass
class StubReadinessChecker:
    ready: bool

    async def is_ready(self) -> bool:
        return self.ready


@dataclass
class MemoryEventRecorder:
    events: list[dict[str, object]] = field(default_factory=list)

    def request_failed(self, *, request_id: str, status: int, error_category: str) -> None:
        self.events.append(
            {
                "event": "request_failed",
                "request_id": request_id,
                "status": status,
                "error_category": error_category,
            }
        )


def make_app(
    settings: Settings,
    *,
    ready: bool = True,
    recorder: MemoryEventRecorder | None = None,
) -> FastAPI:
    return create_app(
        settings,
        readiness_checker=StubReadinessChecker(ready),
        event_recorder=recorder or MemoryEventRecorder(),
    )


def test_live_and_ready_are_separate(test_settings: Settings) -> None:
    app = make_app(test_settings, ready=False)

    with TestClient(app) as client:
        live = client.get("/health/live")
        ready = client.get("/health/ready")

    assert live.status_code == 200
    assert live.json() == {"status": "ok"}
    assert ready.status_code == 503
    assert ready.json() == {"status": "unavailable"}


def test_ready_succeeds_when_dependency_is_ready(test_settings: Settings) -> None:
    with TestClient(make_app(test_settings)) as client:
        response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ready_records_diagnostic_when_readiness_check_raises(
    test_settings: Settings,
    caplog: pytest.LogCaptureFixture,
) -> None:
    @dataclass
    class RaisingReadinessChecker:
        async def is_ready(self) -> bool:
            raise RuntimeError("connection refused")

    app = create_app(
        test_settings,
        readiness_checker=RaisingReadinessChecker(),
        event_recorder=MemoryEventRecorder(),
    )

    with caplog.at_level(logging.ERROR, logger="kitchen_server"), TestClient(app) as client:
        response = client.get("/health/ready")

    assert response.status_code == 503
    assert response.json() == {"status": "unavailable"}
    records = [record for record in caplog.records if record.msg == "readiness_check_failed"]
    assert [record.__dict__["error_category"] for record in records] == ["RuntimeError"]
    assert "connection refused" not in caplog.text


def test_apple_flow_is_registered_without_exposing_credentials(test_settings: Settings) -> None:
    with TestClient(make_app(test_settings)) as client:
        response = client.post(
            "/v1/auth/apple/flow",
            json={"flowId": "flow-1234567890123456", "nonce": "nonce-1234567890123456"},
        )

    assert response.status_code == 204
    assert response.content == b""


def test_request_id_accepts_only_controlled_values(test_settings: Settings) -> None:
    with TestClient(make_app(test_settings)) as client:
        accepted = client.get("/health/live", headers={"X-Request-ID": "device_123-ok"})
        generated = client.get("/health/live", headers={"X-Request-ID": "bad value/secret"})

    assert accepted.headers["X-Request-ID"] == "device_123-ok"
    assert generated.headers["X-Request-ID"] != "bad value/secret"
    assert len(generated.headers["X-Request-ID"]) == 36


def test_expected_http_error_records_stable_category(test_settings: Settings) -> None:
    recorder = MemoryEventRecorder()
    app = make_app(test_settings, recorder=recorder)

    with TestClient(app) as client:
        response = client.get("/missing", headers={"X-Request-ID": "missing-request"})

    assert response.status_code == 404
    assert recorder.events == [
        {
            "event": "request_failed",
            "request_id": "missing-request",
            "status": 404,
            "error_category": "client_error",
        }
    ]


def test_unhandled_error_is_opaque_and_records_only_safe_fields(
    test_settings: Settings,
) -> None:
    recorder = MemoryEventRecorder()
    app = make_app(test_settings, recorder=recorder)
    secret_values = {
        "authorization": "Bearer access-token-secret",
        "phone": "13812345678",
        "recipe": "private recipe body",
        "provider_key": "third-party-key",
    }

    @app.post("/__test/error")
    async def raise_error() -> None:
        raise RuntimeError("internal database topology")

    with TestClient(app, raise_server_exceptions=False) as client:
        response = client.post(
            "/__test/error",
            headers={
                "Authorization": secret_values["authorization"],
                "X-Request-ID": "safe-request-id",
            },
            json=secret_values,
        )

    assert response.status_code == 500
    assert response.json() == {"detail": "internal_server_error"}
    assert response.headers["X-Request-ID"] == "safe-request-id"
    assert recorder.events == [
        {
            "event": "request_failed",
            "request_id": "safe-request-id",
            "status": 500,
            "error_category": "internal_error",
        }
    ]
    serialized_events = json.dumps(recorder.events)
    for secret in secret_values.values():
        assert secret not in serialized_events


def test_json_event_recorder_emits_allowlisted_structure() -> None:
    stream = io.StringIO()
    logger = logging.Logger("safe-event-test")
    handler = logging.StreamHandler(stream)
    handler.setFormatter(SafeJsonFormatter())
    logger.addHandler(handler)

    JsonSafeEventRecorder(logger).request_failed(
        request_id="request-42",
        status=500,
        error_category="internal_error",
    )

    event = json.loads(stream.getvalue())
    assert event["event"] == "request_failed"
    assert event["request_id"] == "request-42"
    assert event["status"] == 500
    assert event["error_category"] == "internal_error"
    assert set(event) == {
        "timestamp",
        "level",
        "event",
        "request_id",
        "status",
        "error_category",
    }


def test_database_unavailable_rejects_readiness(test_settings: Settings) -> None:
    unavailable_settings = test_settings.model_copy(
        update={
            "database_url": test_settings.database_url.__class__(
                "postgresql://kitchen_test:test-only@127.0.0.1:1/kitchen_test"
            )
        }
    )
    app = create_app(unavailable_settings)

    with TestClient(app) as client:
        response = client.get("/health/ready")

    assert response.status_code == 503
    assert response.json() == {"status": "unavailable"}


def test_configuration_failure_output_is_opaque(
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    from kitchen_server import main as server_main
    from kitchen_server.infrastructure.config import RuntimeConfigurationError

    def fail_to_load() -> Settings:
        raise RuntimeConfigurationError("runtime_configuration_invalid")

    monkeypatch.setattr(server_main, "load_settings", fail_to_load)

    with pytest.raises(SystemExit) as error:
        server_main.main()

    assert error.value.code == 2
    output = capsys.readouterr().err
    assert json.loads(output) == {
        "event": "startup_failed",
        "error_category": "configuration_invalid",
    }
