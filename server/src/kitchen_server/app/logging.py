from __future__ import annotations

import json
import logging
from datetime import UTC, datetime
from typing import Protocol


class SafeEventRecorder(Protocol):
    def request_failed(self, *, request_id: str, status: int, error_category: str) -> None: ...


class SafeJsonFormatter(logging.Formatter):
    _allowed_fields = ("request_id", "status", "error_category")

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "timestamp": datetime.now(UTC).isoformat(),
            "level": record.levelname.lower(),
            "event": str(record.msg),
        }
        for field in self._allowed_fields:
            if hasattr(record, field):
                payload[field] = getattr(record, field)
        return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def configure_logging(level: str) -> logging.Logger:
    logger = logging.getLogger("kitchen_server")
    logger.handlers.clear()
    handler = logging.StreamHandler()
    handler.setFormatter(SafeJsonFormatter())
    logger.addHandler(handler)
    logger.setLevel(level.upper())
    logger.propagate = False
    return logger


class JsonSafeEventRecorder:
    def __init__(self, logger: logging.Logger | None = None) -> None:
        self._logger = logger or logging.getLogger("kitchen_server")

    def request_failed(self, *, request_id: str, status: int, error_category: str) -> None:
        self._logger.error(
            "request_failed",
            extra={
                "request_id": request_id,
                "status": status,
                "error_category": error_category,
            },
        )
