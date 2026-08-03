from __future__ import annotations

import asyncio
import os
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from kitchen_server.app.factory import create_app
from kitchen_server.infrastructure.config import load_settings
from kitchen_server.infrastructure.database import to_async_database_url

pytestmark = pytest.mark.integration

SERVER_ROOT = Path(__file__).resolve().parents[2]


def require_database_url() -> str:
    database_url = os.environ.get("DATABASE_URL")
    if database_url is None:
        pytest.skip("DATABASE_URL is required for PostgreSQL integration tests")
    settings = load_settings({"APP_ENV": "testing", "DATABASE_URL": database_url})
    return settings.database_url_value


def alembic_config(database_url: str) -> Config:
    config = Config(str(SERVER_ROOT / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", database_url)
    return config


async def scalar(database_url: str, statement: str) -> object:
    engine = create_async_engine(to_async_database_url(database_url))
    try:
        async with engine.connect() as connection:
            return await connection.scalar(text(statement))
    finally:
        await engine.dispose()


def test_migration_is_repeatable_reversible_and_ready() -> None:
    database_url = require_database_url()
    config = alembic_config(database_url)

    command.downgrade(config, "base")
    command.upgrade(config, "head")
    assert (
        asyncio.run(
            scalar(database_url, "SELECT schema_version FROM runtime_metadata WHERE id = 1")
        )
        == 1
    )

    command.upgrade(config, "head")
    assert asyncio.run(scalar(database_url, "SELECT count(*) FROM runtime_metadata")) == 1

    settings = load_settings({"APP_ENV": "testing", "DATABASE_URL": database_url})
    with TestClient(create_app(settings)) as client:
        response = client.get("/health/ready")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

    command.downgrade(config, "base")
    assert (
        asyncio.run(scalar(database_url, "SELECT to_regclass('public.runtime_metadata')")) is None
    )
