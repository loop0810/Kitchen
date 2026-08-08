from __future__ import annotations

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """服务端所有业务表共享的 SQLAlchemy 元数据根。"""
