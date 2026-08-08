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
from kitchen_server.auth.service import (
    AuthError,
    AuthService,
    SecurityAuditRecorder,
    VerifiedIdentityAssertion,
)
from kitchen_server.infrastructure.config import load_settings
from kitchen_server.infrastructure.database import Database, to_async_database_url

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
    assert (
        asyncio.run(
            scalar(
                database_url,
                "SELECT count(*) FROM information_schema.tables WHERE table_name IN "
                "('users', 'auth_identities', 'device_sessions', 'refresh_token_families', "
                "'auth_idempotency_records')",
            )
        )
        == 5
    )
    assert (
        asyncio.run(
            scalar(
                database_url,
                "SELECT count(*) FROM pg_constraint WHERE conname = "
                "'uq_auth_identity_provider_subject_scope'",
            )
        )
        == 1
    )
    assert (
        asyncio.run(
            scalar(
                database_url,
                "SELECT count(*) FROM information_schema.columns WHERE table_name = "
                "'auth_identities' AND column_name IN "
                "('status', 'email', 'given_name', 'family_name', 'revoked_at')",
            )
        )
        == 5
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


async def exercise_auth(database_url: str) -> None:
    settings = load_settings({"APP_ENV": "testing", "DATABASE_URL": database_url})
    database = Database(settings)
    audit = _AuditRecorder()
    service = AuthService(settings, audit_recorder=audit)
    assertion = VerifiedIdentityAssertion("test", "subject-1", "integration")
    try:
        async with database.session() as session:
            first = await service.authenticate(session, assertion, device_name="模拟器")
        async with database.session() as session:
            second = await service.authenticate(session, assertion, device_name="模拟器")
        assert first.user_id == second.user_id

        other_assertion = VerifiedIdentityAssertion("test", "subject-2", "integration")
        async with database.session() as session:
            other = await service.authenticate(session, other_assertion, device_name="另一台设备")
        async with database.session() as session:
            with pytest.raises(AuthError, match="identity_conflict"):
                await service.bind_identity(
                    session,
                    first.user_id,
                    other_assertion,
                    recently_reauthenticated=True,
                )
        assert other.user_id != first.user_id

        async with database.session() as session:
            refreshed = await service.refresh(session, first.refresh_token)
        assert refreshed.refresh_token != first.refresh_token
        async with database.session() as session:
            with pytest.raises(AuthError, match="session_replay_detected"):
                await service.refresh(session, first.refresh_token)
        assert audit.events == [("refresh_replay_detected", None, first.session_id)]

        async with database.session() as session:
            await service.save_idempotency(
                session,
                user_id=first.user_id,
                operation="bind_identity",
                key="idem-1",
                request_hash="hash-1",
                response_status=201,
                response_json='{"ok":true}',
            )
            stored = await service.get_idempotency(
                session, first.user_id, "bind_identity", "idem-1", "hash-1"
            )
            assert stored is not None and stored.response_json == '{"ok":true}'
            with pytest.raises(AuthError, match="idempotency_conflict"):
                await service.get_idempotency(
                    session, first.user_id, "bind_identity", "idem-1", "different"
                )

        async with database.session() as session:
            await service.request_account_deletion(
                session,
                first.user_id,
                recently_reauthenticated=True,
            )
        async with database.session() as session:
            await service.run_account_cleanup(session, first.user_id)
    finally:
        await database.dispose()


def test_auth_account_session_flow() -> None:
    database_url = require_database_url()
    config = alembic_config(database_url)
    command.downgrade(config, "base")
    command.upgrade(config, "head")
    asyncio.run(exercise_auth(database_url))
    command.downgrade(config, "base")


class _AuditRecorder(SecurityAuditRecorder):
    def __init__(self) -> None:
        self.events: list[tuple[str, str | None, str | None]] = []

    def security_event(self, *, event: str, user_id: str | None, session_id: str | None) -> None:
        self.events.append((event, user_id, session_id))
