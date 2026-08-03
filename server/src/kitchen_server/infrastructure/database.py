from __future__ import annotations

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
        except SQLAlchemyError:
            return False

    async def dispose(self) -> None:
        await self.engine.dispose()
