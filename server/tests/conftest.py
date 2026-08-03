import pytest

from kitchen_server.infrastructure.config import Settings, load_settings


@pytest.fixture
def test_settings() -> Settings:
    return load_settings(
        {
            "APP_ENV": "testing",
            "DATABASE_URL": "postgresql://kitchen_test:test-only@127.0.0.1:5433/kitchen_test",
        }
    )
