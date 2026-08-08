from datetime import UTC, datetime, timedelta

import pytest

from kitchen_server.auth.service import AuthError, _tokens, verify_access_token
from kitchen_server.infrastructure.config import load_settings


def test_access_token_contains_minimal_claims_and_verifies() -> None:
    settings = load_settings(
        {
            "APP_ENV": "testing",
            "DATABASE_URL": "postgresql://kitchen_test:test-only@127.0.0.1:5433/kitchen_test",
            "AUTH_SIGNING_SECRET": "unit-test-secret",
        }
    )
    now = datetime(2026, 8, 8, tzinfo=UTC)
    tokens = _tokens(
        settings,
        "user-1",
        "session-1",
        "refresh-value",
        now,
        now + timedelta(days=30),
    )

    payload = verify_access_token(settings, tokens.access_token, now=now)

    assert payload == {
        "exp": int(tokens.access_expires_at.timestamp()),
        "iat": int(now.timestamp()),
        "sid": "session-1",
        "sub": "user-1",
        "tokenType": "access",
    }


def test_access_token_rejects_tampering_and_expiry() -> None:
    settings = load_settings(
        {
            "APP_ENV": "testing",
            "DATABASE_URL": "postgresql://kitchen_test:test-only@127.0.0.1:5433/kitchen_test",
            "AUTH_SIGNING_SECRET": "unit-test-secret",
            "ACCESS_TOKEN_TTL_SECONDS": "60",
        }
    )
    now = datetime(2026, 8, 8, tzinfo=UTC)
    tokens = _tokens(
        settings,
        "user-1",
        "session-1",
        "refresh-value",
        now,
        now + timedelta(days=30),
    )

    with pytest.raises(AuthError, match="invalid_session"):
        verify_access_token(settings, f"{tokens.access_token}tampered", now=now)
    with pytest.raises(AuthError, match="invalid_session"):
        verify_access_token(settings, tokens.access_token, now=now + timedelta(seconds=61))


def test_auth_error_uses_non_enumerating_contract_envelope() -> None:
    error = AuthError("identity_conflict", 409)

    assert error.envelope("request-1") == {
        "error": {
            "code": "identity_conflict",
            "message": "身份无法绑定",
            "requestId": "request-1",
        }
    }
