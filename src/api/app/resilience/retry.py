"""Retry policies with exponential backoff.

Provides configurable retry behavior for transient failures
with support for exponential backoff and jitter.
"""

import logging
import random
from dataclasses import dataclass, field
from functools import wraps
from typing import Any, Callable, Optional, Type, TypeVar, ParamSpec

from tenacity import (
    retry,
    stop_after_attempt,
    stop_after_delay,
    wait_exponential,
    wait_exponential_jitter,
    wait_fixed,
    retry_if_exception_type,
    retry_if_result,
    before_sleep_log,
    after_log,
)

logger = logging.getLogger(__name__)

P = ParamSpec("P")
T = TypeVar("T")


@dataclass
class RetryConfig:
    """Configuration for retry behavior."""

    max_attempts: int = 3
    max_delay_seconds: float = 60.0
    initial_delay_seconds: float = 1.0
    exponential_base: float = 2.0
    jitter: bool = True
    retry_exceptions: tuple[Type[Exception], ...] = field(
        default_factory=lambda: (Exception,)
    )
    exclude_exceptions: tuple[Type[Exception], ...] = field(default_factory=tuple)

    def __post_init__(self):
        """Validate configuration."""
        if self.max_attempts < 1:
            raise ValueError("max_attempts must be at least 1")
        if self.initial_delay_seconds <= 0:
            raise ValueError("initial_delay_seconds must be positive")


# Pre-defined retry configurations
RETRY_CONFIGS = {
    "default": RetryConfig(),
    "aggressive": RetryConfig(
        max_attempts=5,
        max_delay_seconds=120.0,
        initial_delay_seconds=0.5,
    ),
    "conservative": RetryConfig(
        max_attempts=2,
        max_delay_seconds=30.0,
        initial_delay_seconds=2.0,
    ),
    "database": RetryConfig(
        max_attempts=3,
        initial_delay_seconds=0.1,
        max_delay_seconds=5.0,
        retry_exceptions=(ConnectionError, TimeoutError),
    ),
    "http": RetryConfig(
        max_attempts=3,
        initial_delay_seconds=1.0,
        max_delay_seconds=10.0,
        jitter=True,
    ),
    "idempotent": RetryConfig(
        max_attempts=5,
        initial_delay_seconds=0.5,
        max_delay_seconds=30.0,
    ),
}


def create_retry_decorator(
    config: Optional[RetryConfig] = None,
    config_name: Optional[str] = None,
    on_retry: Optional[Callable[[int, Exception], None]] = None,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Create a retry decorator with specified configuration.

    Args:
        config: RetryConfig instance.
        config_name: Name of pre-defined config (default, aggressive, etc).
        on_retry: Callback function called on each retry.

    Returns:
        Retry decorator.

    Example:
        @create_retry_decorator(config_name="http")
        async def fetch_data():
            ...
    """
    if config is None:
        config = RETRY_CONFIGS.get(config_name or "default", RETRY_CONFIGS["default"])

    # Build wait strategy
    if config.jitter:
        wait_strategy = wait_exponential_jitter(
            initial=config.initial_delay_seconds,
            max=config.max_delay_seconds,
            exp_base=config.exponential_base,
        )
    else:
        wait_strategy = wait_exponential(
            multiplier=config.initial_delay_seconds,
            min=config.initial_delay_seconds,
            max=config.max_delay_seconds,
            exp_base=config.exponential_base,
        )

    # Build retry condition
    retry_condition = retry_if_exception_type(config.retry_exceptions)

    # Add before/after logging
    callbacks = []
    if on_retry:
        def before_sleep_callback(retry_state):
            on_retry(retry_state.attempt_number, retry_state.outcome.exception())

        callbacks.append(before_sleep_callback)

    return retry(
        stop=stop_after_attempt(config.max_attempts),
        wait=wait_strategy,
        retry=retry_condition,
        before_sleep=before_sleep_log(logger, logging.WARNING),
        after=after_log(logger, logging.DEBUG),
        reraise=True,
    )


def retry_with_backoff(
    max_attempts: int = 3,
    initial_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
    jitter: bool = True,
    retry_on: tuple[Type[Exception], ...] = (Exception,),
    exclude: tuple[Type[Exception], ...] = (),
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Decorator for retrying with exponential backoff.

    Args:
        max_attempts: Maximum number of retry attempts.
        initial_delay: Initial delay between retries in seconds.
        max_delay: Maximum delay between retries in seconds.
        exponential_base: Base for exponential backoff calculation.
        jitter: Add random jitter to delays to prevent thundering herd.
        retry_on: Tuple of exception types to retry on.
        exclude: Tuple of exception types to not retry on.

    Returns:
        Decorator function.

    Example:
        @retry_with_backoff(max_attempts=5, retry_on=(ConnectionError, TimeoutError))
        async def connect_to_service():
            ...
    """
    config = RetryConfig(
        max_attempts=max_attempts,
        initial_delay_seconds=initial_delay,
        max_delay_seconds=max_delay,
        exponential_base=exponential_base,
        jitter=jitter,
        retry_exceptions=retry_on,
        exclude_exceptions=exclude,
    )

    return create_retry_decorator(config)


def retry_on_result(
    predicate: Callable[[Any], bool],
    max_attempts: int = 3,
    delay: float = 1.0,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Retry until result matches predicate.

    Args:
        predicate: Function that returns True if result should trigger retry.
        max_attempts: Maximum number of attempts.
        delay: Fixed delay between attempts.

    Returns:
        Decorator function.

    Example:
        @retry_on_result(lambda r: r is None, max_attempts=5)
        async def poll_for_result():
            ...
    """
    return retry(
        stop=stop_after_attempt(max_attempts),
        wait=wait_fixed(delay),
        retry=retry_if_result(predicate),
        reraise=True,
    )


class RetryBudget:
    """Track retry budget to prevent retry storms.

    Limits the percentage of requests that can be retries
    to prevent cascading failures.
    """

    def __init__(
        self,
        budget_percent: float = 20.0,
        window_seconds: float = 10.0,
        min_retries_per_second: float = 10.0,
    ):
        """Initialize retry budget.

        Args:
            budget_percent: Maximum percentage of requests that can be retries.
            window_seconds: Time window for calculating budget.
            min_retries_per_second: Minimum retries allowed regardless of budget.
        """
        self.budget_percent = budget_percent
        self.window_seconds = window_seconds
        self.min_retries_per_second = min_retries_per_second
        self._requests: list[float] = []
        self._retries: list[float] = []

    def record_request(self) -> None:
        """Record a request."""
        import time

        now = time.time()
        self._requests.append(now)
        self._cleanup(now)

    def record_retry(self) -> None:
        """Record a retry attempt."""
        import time

        now = time.time()
        self._retries.append(now)
        self._cleanup(now)

    def can_retry(self) -> bool:
        """Check if retry is allowed within budget.

        Returns:
            True if retry is allowed.
        """
        import time

        now = time.time()
        self._cleanup(now)

        # Always allow minimum retries
        retry_rate = len(self._retries) / self.window_seconds
        if retry_rate < self.min_retries_per_second:
            return True

        # Check budget
        if not self._requests:
            return True

        retry_percent = (len(self._retries) / len(self._requests)) * 100
        return retry_percent < self.budget_percent

    def _cleanup(self, now: float) -> None:
        """Remove old entries outside window."""
        cutoff = now - self.window_seconds
        self._requests = [t for t in self._requests if t > cutoff]
        self._retries = [t for t in self._retries if t > cutoff]
