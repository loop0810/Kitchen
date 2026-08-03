from typing import Protocol


class RuntimeReadinessChecker(Protocol):
    async def is_ready(self) -> bool: ...
