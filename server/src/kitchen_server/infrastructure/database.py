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
    # 配置允许普通 PostgreSQL URL，但应用统一转换为 asyncpg 驱动，
    # 这样连接创建和 SQLAlchemy Session 的异步语义不会散落在调用方。
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
        # 事务由业务服务显式 commit；未处理异常时这里统一 rollback，
        # 防止连接回池时带着失败事务，影响下一次请求。
        async with self.session_factory() as session:
            try:
                yield session
            except Exception:
                await session.rollback()
                raise

    async def is_ready(self) -> bool:
        # readiness 使用迁移写入的 runtime_metadata 作为“schema 已就绪”信号，
        # 不把能建立 TCP 连接误判成数据库已经可服务。
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
