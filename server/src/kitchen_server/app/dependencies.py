from __future__ import annotations

from collections.abc import AsyncIterator
from typing import cast

from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from kitchen_server.infrastructure.database import Database


async def get_database_session(request: Request) -> AsyncIterator[AsyncSession]:
    database = cast(Database | None, request.app.state.database)
    if database is None:
        raise RuntimeError("database_not_configured")
    async with database.session() as session:
        yield session
