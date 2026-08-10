from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from sqlalchemy import text
from sqlalchemy.engine import URL, make_url
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from kitchen_server.infrastructure.config import Settings

_logger = logging.getLogger("kitchen_server")


def to_async_database_url(database_url: str) -> URL:
    url = make_url(database_url)
    if url.drivername in {"postgres", "postgresql"}:
        return url.set(drivername="postgresql+asyncpg")
    if url.drivername == "postgresql+asyncpg":
        return url
    raise ValueError("database_url_invalid")


class Database:
    def __init__(self, settings: Settings) -> None:
        self.engine: AsyncEngine = create_async_engine(
            to_async_database_url(settings.database_url_value),
            pool_pre_ping=True,
        )
        self.session_factory = async_sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False,
        )

    @asynccontextmanager
    async def session(self) -> AsyncIterator[AsyncSession]:
        async with self.session_factory() as session:
            try:
                yield session
            except Exception:
                await session.rollback()
                raise

    async def is_ready(self) -> bool:
        try:
            async with self.engine.connect() as connection:
                schema_version = await connection.scalar(
                    text("SELECT schema_version FROM runtime_metadata WHERE id = 1")
                )
            return bool(schema_version == 1)
        except SQLAlchemyError as error:
            # Readiness only exposes a boolean, so the failure cause has to reach the
            # log; the exception type is a stable, payload-free category.
            _logger.error(
                "database_readiness_failed",
                extra={"error_category": type(error).__name__},
            )
            return False

    async def dispose(self) -> None:
        await self.engine.dispose()
