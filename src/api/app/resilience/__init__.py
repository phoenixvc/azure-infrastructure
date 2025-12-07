"""Resilience patterns for fault tolerance.

Provides circuit breaker, retry policies, and timeout handling
for robust service communication.
"""

from .circuit_breaker import (
    CircuitBreaker,
    circuit_breaker,
    CircuitBreakerError,
    CircuitBreakerOpenError,
)
from .retry import (
    retry_with_backoff,
    RetryConfig,
    create_retry_decorator,
)
from .timeout import (
    with_timeout,
    TimeoutConfig,
)

__all__ = [
    # Circuit Breaker
    "CircuitBreaker",
    "circuit_breaker",
    "CircuitBreakerError",
    "CircuitBreakerOpenError",
    # Retry
    "retry_with_backoff",
    "RetryConfig",
    "create_retry_decorator",
    # Timeout
    "with_timeout",
    "TimeoutConfig",
]
