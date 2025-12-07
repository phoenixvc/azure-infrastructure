"""Circuit breaker pattern implementation.

Prevents cascading failures by detecting failures and temporarily
blocking requests to failing services.
"""

import logging
from dataclasses import dataclass
from enum import Enum
from functools import wraps
from typing import Any, Callable, Optional, TypeVar, ParamSpec
import time

import pybreaker

logger = logging.getLogger(__name__)

P = ParamSpec("P")
T = TypeVar("T")


class CircuitState(Enum):
    """Circuit breaker states."""

    CLOSED = "closed"  # Normal operation, requests pass through
    OPEN = "open"  # Failure threshold exceeded, requests blocked
    HALF_OPEN = "half_open"  # Testing if service recovered


class CircuitBreakerError(Exception):
    """Base exception for circuit breaker errors."""

    pass


class CircuitBreakerOpenError(CircuitBreakerError):
    """Raised when circuit breaker is open and rejecting requests."""

    def __init__(self, breaker_name: str, remaining_timeout: float):
        self.breaker_name = breaker_name
        self.remaining_timeout = remaining_timeout
        super().__init__(
            f"Circuit breaker '{breaker_name}' is open. "
            f"Retry after {remaining_timeout:.1f} seconds."
        )


@dataclass
class CircuitBreakerConfig:
    """Configuration for circuit breaker behavior."""

    fail_max: int = 5  # Failures before opening circuit
    reset_timeout: int = 30  # Seconds before attempting recovery
    exclude: tuple = ()  # Exceptions that don't count as failures
    listeners: tuple = ()  # Event listeners for state changes


class CircuitBreakerListener(pybreaker.CircuitBreakerListener):
    """Listener for circuit breaker state changes."""

    def __init__(self, name: str):
        self.name = name

    def state_change(self, cb: pybreaker.CircuitBreaker, old_state: str, new_state: str) -> None:
        """Log state changes."""
        logger.warning(
            f"Circuit breaker '{self.name}' state changed: {old_state} -> {new_state}"
        )

    def failure(self, cb: pybreaker.CircuitBreaker, exc: Exception) -> None:
        """Log failures."""
        logger.warning(
            f"Circuit breaker '{self.name}' recorded failure: {exc}"
        )

    def success(self, cb: pybreaker.CircuitBreaker) -> None:
        """Log successful calls when in half-open state."""
        if cb.current_state == pybreaker.STATE_HALF_OPEN:
            logger.info(f"Circuit breaker '{self.name}' successful test call")


class CircuitBreaker:
    """Circuit breaker wrapper with enhanced functionality.

    Example:
        cb = CircuitBreaker("payment-service", fail_max=3, reset_timeout=60)

        @cb
        async def call_payment_service():
            ...

        # Or use directly
        result = await cb.call(call_payment_service)
    """

    def __init__(
        self,
        name: str,
        fail_max: int = 5,
        reset_timeout: int = 30,
        exclude: tuple = (),
    ):
        """Initialize circuit breaker.

        Args:
            name: Identifier for this circuit breaker.
            fail_max: Number of failures before opening circuit.
            reset_timeout: Seconds before attempting to close circuit.
            exclude: Exception types that don't count as failures.
        """
        self.name = name
        self._listener = CircuitBreakerListener(name)
        self._breaker = pybreaker.CircuitBreaker(
            name=name,
            fail_max=fail_max,
            reset_timeout=reset_timeout,
            exclude=list(exclude),
            listeners=[self._listener],
        )

    @property
    def state(self) -> CircuitState:
        """Get current circuit state."""
        state_map = {
            pybreaker.STATE_CLOSED: CircuitState.CLOSED,
            pybreaker.STATE_OPEN: CircuitState.OPEN,
            pybreaker.STATE_HALF_OPEN: CircuitState.HALF_OPEN,
        }
        return state_map.get(self._breaker.current_state, CircuitState.CLOSED)

    @property
    def failure_count(self) -> int:
        """Get current failure count."""
        return self._breaker.fail_counter

    @property
    def is_open(self) -> bool:
        """Check if circuit is open."""
        return self._breaker.current_state == pybreaker.STATE_OPEN

    def reset(self) -> None:
        """Manually reset the circuit breaker to closed state."""
        self._breaker.close()
        logger.info(f"Circuit breaker '{self.name}' manually reset")

    def __call__(self, func: Callable[P, T]) -> Callable[P, T]:
        """Decorator to wrap function with circuit breaker.

        Args:
            func: Function to protect with circuit breaker.

        Returns:
            Wrapped function.
        """
        @wraps(func)
        async def async_wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
            return await self.call_async(func, *args, **kwargs)

        @wraps(func)
        def sync_wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
            return self.call(func, *args, **kwargs)

        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    def call(self, func: Callable[P, T], *args: P.args, **kwargs: P.kwargs) -> T:
        """Execute a synchronous function through the circuit breaker.

        Args:
            func: Function to execute.
            *args: Positional arguments.
            **kwargs: Keyword arguments.

        Returns:
            Function result.

        Raises:
            CircuitBreakerOpenError: If circuit is open.
        """
        try:
            return self._breaker.call(func, *args, **kwargs)
        except pybreaker.CircuitBreakerError:
            remaining = self._get_remaining_timeout()
            raise CircuitBreakerOpenError(self.name, remaining)

    async def call_async(
        self,
        func: Callable[P, T],
        *args: P.args,
        **kwargs: P.kwargs,
    ) -> T:
        """Execute an async function through the circuit breaker.

        Args:
            func: Async function to execute.
            *args: Positional arguments.
            **kwargs: Keyword arguments.

        Returns:
            Function result.

        Raises:
            CircuitBreakerOpenError: If circuit is open.
        """
        if self._breaker.current_state == pybreaker.STATE_OPEN:
            remaining = self._get_remaining_timeout()
            raise CircuitBreakerOpenError(self.name, remaining)

        try:
            result = await func(*args, **kwargs)
            self._breaker.success()
            return result
        except Exception as exc:
            if not self._is_excluded(exc):
                self._breaker.failure(exc)
            raise

    def _get_remaining_timeout(self) -> float:
        """Calculate remaining timeout before retry."""
        if hasattr(self._breaker, "_state_opened_at"):
            elapsed = time.time() - self._breaker._state_opened_at
            return max(0, self._breaker.reset_timeout - elapsed)
        return float(self._breaker.reset_timeout)

    def _is_excluded(self, exc: Exception) -> bool:
        """Check if exception is excluded from failure count."""
        return isinstance(exc, tuple(self._breaker.exclude))


# Default circuit breakers for common services
_circuit_breakers: dict[str, CircuitBreaker] = {}


def circuit_breaker(
    name: str,
    fail_max: int = 5,
    reset_timeout: int = 30,
    exclude: tuple = (),
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Decorator factory for circuit breaker protection.

    Args:
        name: Circuit breaker identifier.
        fail_max: Failures before opening circuit.
        reset_timeout: Seconds before attempting recovery.
        exclude: Exception types to exclude from failure count.

    Returns:
        Decorator function.

    Example:
        @circuit_breaker("external-api", fail_max=3, reset_timeout=60)
        async def call_external_api():
            ...
    """
    # Get or create circuit breaker
    if name not in _circuit_breakers:
        _circuit_breakers[name] = CircuitBreaker(
            name=name,
            fail_max=fail_max,
            reset_timeout=reset_timeout,
            exclude=exclude,
        )

    cb = _circuit_breakers[name]

    def decorator(func: Callable[P, T]) -> Callable[P, T]:
        return cb(func)

    return decorator


def get_circuit_breaker(name: str) -> Optional[CircuitBreaker]:
    """Get a circuit breaker by name.

    Args:
        name: Circuit breaker identifier.

    Returns:
        CircuitBreaker instance or None if not found.
    """
    return _circuit_breakers.get(name)


def get_all_circuit_breakers() -> dict[str, CircuitBreaker]:
    """Get all registered circuit breakers.

    Returns:
        Dictionary of circuit breaker name to instance.
    """
    return _circuit_breakers.copy()
