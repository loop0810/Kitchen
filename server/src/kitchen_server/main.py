from __future__ import annotations

import json
import sys

import uvicorn

from kitchen_server.app.factory import create_app
from kitchen_server.app.logging import configure_logging
from kitchen_server.infrastructure.config import RuntimeConfigurationError, load_settings


def main() -> None:
    try:
        settings = load_settings()
    except RuntimeConfigurationError:
        sys.stderr.write(
            json.dumps(
                {
                    "event": "startup_failed",
                    "error_category": "configuration_invalid",
                },
                separators=(",", ":"),
            )
            + "\n"
        )
        raise SystemExit(2) from None

    configure_logging(settings.resolved_log_level)
    app = create_app(settings)
    uvicorn.run(
        app,
        host=settings.host,
        port=settings.port,
        log_config=None,
        access_log=False,
    )
