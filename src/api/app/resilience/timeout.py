"""Timeout handling for async operations.

Provides configurable timeout wrappers to prevent
hanging requests and ensure responsive services.
"""

import asyncio
import logging
from dataclasses import dataclass
from functools import wraps
from typing import Any, Callable, Optional, TypeVar, ParamSpec

logger = logging.getLogger(__name__)

P = ParamSpec("P")
T = TypeVar("T")


class TimeoutError(Exception):
    """Raised when an operation times out."""

    def __init__(self, operation: str, timeout_seconds: float):
        self.operation = operation
        self.timeout_seconds = timeout_seconds
        super().__init__(
            f"Operation '{operation}' timed out after {timeout_seconds} seconds"
        )


@dataclass
class TimeoutConfig:
    """Configuration for timeout behavior."""

    default_timeout: float = 30.0
    connect_timeout: float = 5.0
    read_timeout: float = 30.0
    write_timeout: float = 30.0


# Pre-defined timeout configurations
TIMEOUT_CONFIGS = {
    "default": TimeoutConfig(),
    "fast": TimeoutConfig(
        default_timeout=5.0,
        connect_timeout=2.0,
        read_timeout=5.0,
        write_timeout=5.0,
    ),
    "slow": TimeoutConfig(
        default_timeout=120.0,
        connect_timeout=10.0,
        read_timeout=120.0,
        write_timeout=60.0,
    ),
    "database": TimeoutConfig(
        default_timeout=10.0,
        connect_timeout=5.0,
        read_timeout=10.0,
        write_timeout=10.0,
    ),
    "external_api": TimeoutConfig(
        default_timeout=30.0,
        connect_timeout=5.0,
        read_timeout=30.0,
        write_timeout=10.0,
    ),
}


def with_timeout(
    seconds: Optional[float] = None,
    config_name: Optional[str] = None,
    operation_name: Optional[str] = None,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Decorator to add timeout to async functions.

    Args:
        seconds: Timeout in seconds (overrides config).
        config_name: Name of pre-defined config.
        operation_name: Name for error messages (defaults to function name).

    Returns:
        Decorator function.

    Example:
        @with_timeout(seconds=10)
        async def fetch_data():
            ...

        @with_timeout(config_name="external_api")
        async def call_api():
            ...
    """
    # Get timeout value
    if seconds is not None:
        timeout = seconds
    elif config_name:
        config = TIMEOUT_CONFIGS.get(config_name, TIMEOUT_CONFIGS["default"])
        timeout = config.default_timeout
    else:
        timeout = TIMEOUT_CONFIGS["default"].default_timeout

    def decorator(func: Callable[P, T]) -> Callable[P, T]:
        op_name = operation_name or func.__name__

        @wraps(func)
        async def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
            try:
                return await asyncio.wait_for(
                    func(*args, **kwargs),
                    timeout=timeout,
                )
            except asyncio.TimeoutError:
                logger.error(f"Timeout after {timeout}s: {op_name}")
                raise TimeoutError(op_name, timeout)

        return wrapper

    return decorator


async def run_with_timeout(
    coro: Any,
    timeout_seconds: float,
    operation_name: str = "operation",
) -> Any:
    """Run a coroutine with timeout.

    Args:
        coro: Coroutine to execute.
        timeout_seconds: Maximum execution time.
        operation_name: Name for error messages.

    Returns:
        Result of the coroutine.

    Raises:
        TimeoutError: If operation exceeds timeout.

    Example:
        result = await run_with_timeout(
            fetch_data(),
            timeout_seconds=10,
            operation_name="fetch_data"
        )
    """
    try:
        return await asyncio.wait_for(coro, timeout=timeout_seconds)
    except asyncio.TimeoutError:
        logger.error(f"Timeout after {timeout_seconds}s: {operation_name}")
        raise TimeoutError(operation_name, timeout_seconds)


class AdaptiveTimeout:
    """Adaptive timeout that adjusts based on observed latencies.

    Tracks operation latencies and adjusts timeout based on
    percentile of observed values plus buffer.
    """

    def __init__(
        self,
        initial_timeout: float = 30.0,
        min_timeout: float = 1.0,
        max_timeout: float = 120.0,
        percentile: float = 99.0,
        buffer_multiplier: float = 1.5,
        window_size: int = 100,
    ):
        """Initialize adaptive timeout.

        Args:
            initial_timeout: Starting timeout value.
            min_timeout: Minimum allowed timeout.
            max_timeout: Maximum allowed timeout.
            percentile: Percentile of latencies to use for timeout.
            buffer_multiplier: Multiplier for buffer above percentile.
            window_size: Number of samples to keep.
        """
        self.min_timeout = min_timeout
        self.max_timeout = max_timeout
        self.percentile = percentile
        self.buffer_multiplier = buffer_multiplier
        self.window_size = window_size
        self._latencies: list[float] = []
        self._current_timeout = initial_timeout

    @property
    def current_timeout(self) -> float:
        """Get current adaptive timeout value."""
        return self._current_timeout

    def record_latency(self, latency_seconds: float) -> None:
        """Record an observed latency.

        Args:
            latency_seconds: Observed operation latency.
        """
        self._latencies.append(latency_seconds)

        # Keep only recent samples
        if len(self._latencies) > self.window_size:
            self._latencies = self._latencies[-self.window_size:]

        # Recalculate timeout
        self._update_timeout()

    def record_timeout(self) -> None:
        """Record a timeout occurrence.

        Increases timeout by a small amount when timeouts occur.
        """
        # Increase by 10% on timeout, capped at max
        self._current_timeout = min(
            self.max_timeout,
            self._current_timeout * 1.1,
        )

    def _update_timeout(self) -> None:
        """Update timeout based on observed latencies."""
        if len(self._latencies) < 10:
            return  # Not enough samples

        # Calculate percentile
        sorted_latencies = sorted(self._latencies)
        index = int(len(sorted_latencies) * self.percentile / 100)
        percentile_value = sorted_latencies[min(index, len(sorted_latencies) - 1)]

        # Calculate new timeout with buffer
        new_timeout = percentile_value * self.buffer_multiplier

        # Apply bounds
        self._current_timeout = max(
            self.min_timeout,
            min(self.max_timeout, new_timeout),
        )

    def __call__(self, func: Callable[P, T]) -> Callable[P, T]:
        """Decorator to apply adaptive timeout.

        Args:
            func: Async function to wrap.

        Returns:
            Wrapped function.
        """
        @wraps(func)
        async def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
            import time

            start = time.time()
            try:
                result = await asyncio.wait_for(
                    func(*args, **kwargs),
                    timeout=self._current_timeout,
                )
                # Record successful latency
                self.record_latency(time.time() - start)
                return result
            except asyncio.TimeoutError:
                self.record_timeout()
                raise TimeoutError(func.__name__, self._current_timeout)

        return wrapper
