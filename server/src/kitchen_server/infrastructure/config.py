from __future__ import annotations

import os
from collections.abc import Mapping
from enum import StrEnum
from typing import Literal
from urllib.parse import unquote, urlsplit

from pydantic import Field, SecretStr, ValidationError, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppEnvironment(StrEnum):
    DEVELOPMENT = "development"
    TESTING = "testing"
    PRODUCTION = "production"


class RuntimeConfigurationError(RuntimeError):
    """Stable configuration failure that never includes input values."""


class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore", frozen=True)

    app_env: AppEnvironment = Field(
        default=AppEnvironment.DEVELOPMENT,
        validation_alias="APP_ENV",
    )
    database_url: SecretStr = Field(validation_alias="DATABASE_URL")
    host: str = Field(default="127.0.0.1", validation_alias="HOST")
    port: int = Field(default=8080, ge=1, le=65535, validation_alias="PORT")
    log_level: Literal["debug", "info", "warning", "error", "critical"] | None = Field(
        default=None,
        validation_alias="LOG_LEVEL",
    )
    auth_signing_secret: SecretStr = Field(
        default=SecretStr("development-only-auth-signing-secret"),
        validation_alias="AUTH_SIGNING_SECRET",
    )
    access_token_ttl_seconds: int = Field(
        default=900,
        ge=60,
        le=86_400,
        validation_alias="ACCESS_TOKEN_TTL_SECONDS",
    )
    refresh_token_ttl_seconds: int = Field(
        default=2_592_000,
        ge=3_600,
        le=31_536_000,
        validation_alias="REFRESH_TOKEN_TTL_SECONDS",
    )
    apple_client_id: str | None = Field(default=None, validation_alias="APPLE_CLIENT_ID")
    apple_issuer: str = Field(default="https://appleid.apple.com", validation_alias="APPLE_ISSUER")

    @field_validator("database_url", mode="before")
    @classmethod
    def validate_database_url(cls, value: object) -> object:
        if not isinstance(value, str):
            raise ValueError("database_url_invalid")
        parsed = urlsplit(value)
        if parsed.scheme not in {"postgres", "postgresql", "postgresql+asyncpg"}:
            raise ValueError("database_url_invalid")
        if parsed.hostname is None or not unquote(parsed.path).strip("/"):
            raise ValueError("database_url_invalid")
        return value

    @model_validator(mode="after")
    def protect_test_database(self) -> Settings:
        if self.app_env is AppEnvironment.TESTING:
            database_name = unquote(urlsplit(self.database_url_value).path).strip("/")
            if "test" not in database_name.lower():
                raise ValueError("test_database_required")
        return self

    @property
    def database_url_value(self) -> str:
        return self.database_url.get_secret_value()

    @property
    def resolved_log_level(self) -> str:
        if self.log_level is not None:
            return self.log_level
        if self.app_env is AppEnvironment.PRODUCTION:
            return "info"
        return "debug"


def load_settings(environ: Mapping[str, str] | None = None) -> Settings:
    source = os.environ if environ is None else environ
    try:
        return Settings.model_validate(dict(source))
    except ValidationError:
        raise RuntimeConfigurationError("runtime_configuration_invalid") from None
