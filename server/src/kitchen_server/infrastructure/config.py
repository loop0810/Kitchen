from __future__ import annotations

import os
import re
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


DEVELOPMENT_AUTH_SIGNING_SECRET = "development-only-auth-signing-secret"
DEVELOPMENT_PHONE_OTP_PEPPER = "development-only-phone-otp-pepper"
DEVELOPMENT_PHONE_MOCK_CAPTCHA_TOKEN = "local-captcha-ok"
_DEVELOPMENT_ONLY_SECRETS = frozenset(
    {
        DEVELOPMENT_AUTH_SIGNING_SECRET,
        DEVELOPMENT_PHONE_OTP_PEPPER,
        DEVELOPMENT_PHONE_MOCK_CAPTCHA_TOKEN,
    }
)
_MINIMUM_PRODUCTION_SECRET_LENGTH = 32


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
        default=SecretStr(DEVELOPMENT_AUTH_SIGNING_SECRET),
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
    phone_otp_pepper: SecretStr = Field(
        default=SecretStr(DEVELOPMENT_PHONE_OTP_PEPPER),
        validation_alias="PHONE_OTP_PEPPER",
    )
    phone_auth_mode: Literal["disabled", "mock", "live"] = Field(
        default="disabled", validation_alias="PHONE_AUTH_MODE"
    )
    phone_mock_otp: str = Field(default="111111", validation_alias="PHONE_MOCK_OTP")
    phone_mock_captcha_token: SecretStr = Field(
        default=SecretStr(DEVELOPMENT_PHONE_MOCK_CAPTCHA_TOKEN),
        validation_alias="PHONE_MOCK_CAPTCHA_TOKEN",
    )
    phone_daily_send_limit: int = Field(
        default=100, ge=1, le=1_000_000, validation_alias="PHONE_DAILY_SEND_LIMIT"
    )
    phone_daily_budget_units: int = Field(
        default=100, ge=1, le=1_000_000, validation_alias="PHONE_DAILY_BUDGET_UNITS"
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

    @field_validator("phone_mock_otp")
    @classmethod
    def validate_phone_mock_otp(cls, value: str) -> str:
        if re.fullmatch(r"\d{6}", value) is None:
            raise ValueError("phone_mock_otp_invalid")
        return value

    @field_validator("apple_client_id")
    @classmethod
    def normalize_apple_client_id(cls, value: str | None) -> str | None:
        """空字符串按未配置处理, 避免用空 audience 校验 Apple 身份令牌。"""
        normalized = value.strip() if value is not None else None
        return normalized or None

    @model_validator(mode="after")
    def require_production_secrets(self) -> Settings:
        """生产环境必须显式注入长随机密钥, 且不能启用本地模拟登录。"""
        if self.app_env is not AppEnvironment.PRODUCTION:
            return self
        for secret in (self.auth_signing_secret, self.phone_otp_pepper):
            value = secret.get_secret_value()
            if value in _DEVELOPMENT_ONLY_SECRETS or len(value) < _MINIMUM_PRODUCTION_SECRET_LENGTH:
                raise ValueError("production_secret_required")
        if self.phone_auth_mode == "mock":
            raise ValueError("phone_mock_mode_forbidden")
        return self

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
