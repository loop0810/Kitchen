import pytest

from kitchen_server.infrastructure.config import (
    AppEnvironment,
    RuntimeConfigurationError,
    load_settings,
)


def test_missing_database_url_fails_with_stable_category() -> None:
    with pytest.raises(RuntimeConfigurationError) as error:
        load_settings({"APP_ENV": "development"})

    assert str(error.value) == "runtime_configuration_invalid"


def test_invalid_database_url_does_not_escape_secret() -> None:
    secret = "never-log-this-password"

    with pytest.raises(RuntimeConfigurationError) as error:
        load_settings({"DATABASE_URL": f"mysql://kitchen:{secret}@localhost/kitchen"})

    assert str(error.value) == "runtime_configuration_invalid"
    assert secret not in repr(error.value)


def test_test_environment_rejects_non_test_database() -> None:
    with pytest.raises(RuntimeConfigurationError):
        load_settings(
            {
                "APP_ENV": "testing",
                "DATABASE_URL": "postgresql://kitchen:secret@localhost/kitchen_production",
            }
        )


def test_settings_mask_database_url_and_apply_environment_defaults() -> None:
    secret = "local-password"
    settings = load_settings(
        {"DATABASE_URL": f"postgresql://kitchen:{secret}@localhost/kitchen_development"}
    )

    assert settings.app_env is AppEnvironment.DEVELOPMENT
    assert settings.host == "127.0.0.1"
    assert settings.port == 8080
    assert settings.resolved_log_level == "debug"
    assert secret not in repr(settings)


def test_production_defaults_to_info_logging() -> None:
    settings = load_settings(
        {
            "APP_ENV": "production",
            "DATABASE_URL": "postgresql://kitchen:secret@db.example/kitchen_production",
        }
    )

    assert settings.resolved_log_level == "info"
