from dataclasses import dataclass

from fastapi.testclient import TestClient

from kitchen_server.app.factory import create_app
from kitchen_server.infrastructure.config import Settings


@dataclass
class _Ready:
    async def is_ready(self) -> bool:
        return True


def test_mock_phone_challenge_runs_preflight_and_never_calls_real_supplier(
    test_settings: Settings,
) -> None:
    settings = test_settings.model_copy(update={"phone_auth_mode": "mock"})
    app = create_app(settings, readiness_checker=_Ready())

    with TestClient(app) as client:
        response = client.post(
            "/v1/auth/phone/challenge",
            headers={"Idempotency-Key": "phone-request-123456"},
            json={
                "phone": "+86 13800138000",
                "captchaToken": "local-captcha-ok",
                "installationId": "install-123456",
            },
        )

        assert response.status_code == 200
        assert set(response.json()) == {"challengeId", "retryAfterSeconds"}
        assert app.state.phone_runtime.sender.calls == [
            ("+86****8000", response.json()["challengeId"])
        ]

        repeated = client.post(
            "/v1/auth/phone/challenge",
            headers={"Idempotency-Key": "phone-request-123456"},
            json={
                "phone": "+86 13800138000",
                "captchaToken": "local-captcha-ok",
                "installationId": "install-123456",
            },
        )
        assert repeated.status_code == 200
        assert repeated.json() == response.json()


def test_mock_phone_challenge_rejects_invalid_captcha_before_supplier(
    test_settings: Settings,
) -> None:
    settings = test_settings.model_copy(update={"phone_auth_mode": "mock"})
    app = create_app(settings, readiness_checker=_Ready())

    with TestClient(app) as client:
        response = client.post(
            "/v1/auth/phone/challenge",
            headers={"Idempotency-Key": "phone-request-654321"},
            json={
                "phone": "13800138000",
                "captchaToken": "wrong-token",
                "installationId": "install-654321",
            },
        )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "captcha_invalid"
    assert app.state.phone_runtime.sender.calls == []


def test_mock_phone_challenge_rejects_invalid_phone_before_supplier(
    test_settings: Settings,
) -> None:
    settings = test_settings.model_copy(update={"phone_auth_mode": "mock"})
    app = create_app(settings, readiness_checker=_Ready())

    with TestClient(app) as client:
        response = client.post(
            "/v1/auth/phone/challenge",
            headers={"Idempotency-Key": "phone-request-invalid"},
            json={
                "phone": "01012345678",
                "captchaToken": "local-captcha-ok",
                "installationId": "install-invalid",
            },
        )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "phone_invalid"
    assert app.state.phone_runtime.sender.calls == []


def test_mock_phone_challenge_stops_before_supplier_when_rate_limited(
    test_settings: Settings,
) -> None:
    settings = test_settings.model_copy(update={"phone_auth_mode": "mock"})
    app = create_app(settings, readiness_checker=_Ready())

    with TestClient(app) as client:
        app.state.phone_runtime.risk._max_total = 0
        response = client.post(
            "/v1/auth/phone/challenge",
            headers={"Idempotency-Key": "phone-request-rate-limit"},
            json={
                "phone": "13800138000",
                "captchaToken": "local-captcha-ok",
                "installationId": "install-rate-limit",
            },
        )

    assert response.status_code == 429
    assert response.json()["error"]["code"] == "sms_rate_limited"
    assert app.state.phone_runtime.sender.calls == []


def test_mock_phone_challenge_stops_before_supplier_when_budget_exhausted(
    test_settings: Settings,
) -> None:
    settings = test_settings.model_copy(update={"phone_auth_mode": "mock"})
    app = create_app(settings, readiness_checker=_Ready())

    with TestClient(app) as client:
        app.state.phone_runtime.risk._cost_limit = 0
        response = client.post(
            "/v1/auth/phone/challenge",
            headers={"Idempotency-Key": "phone-request-budget"},
            json={
                "phone": "13800138000",
                "captchaToken": "local-captcha-ok",
                "installationId": "install-budget",
            },
        )

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "sms_budget_exhausted"
    assert app.state.phone_runtime.sender.calls == []
