"""Rate limiting middleware using SlowAPI.

Provides configurable rate limiting for API endpoints with
support for different rate limit strategies.
"""

import logging
from typing import Callable, Optional

from fastapi import FastAPI, Request, Response
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from starlette.responses import JSONResponse

logger = logging.getLogger(__name__)


def get_client_identifier(request: Request) -> str:
    """Get client identifier for rate limiting.

    Uses API key if present, otherwise falls back to IP address.

    Args:
        request: The incoming request.

    Returns:
        Client identifier string.
    """
    # Check for API key in header
    api_key = request.headers.get("X-API-Key")
    if api_key:
        return f"api_key:{api_key}"

    # Check for authenticated user
    if hasattr(request.state, "user") and request.state.user:
        return f"user:{request.state.user.id}"

    # Fall back to IP address
    return get_remote_address(request)


# Create limiter instance
limiter = Limiter(
    key_func=get_client_identifier,
    default_limits=["100/minute"],
    storage_uri="memory://",
)


def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> Response:
    """Handle rate limit exceeded errors.

    Args:
        request: The incoming request.
        exc: The rate limit exception.

    Returns:
        JSON response with rate limit error details.
    """
    logger.warning(
        f"Rate limit exceeded for {get_client_identifier(request)}: {exc.detail}"
    )

    return JSONResponse(
        status_code=429,
        content={
            "error": "rate_limit_exceeded",
            "message": "Too many requests. Please slow down.",
            "detail": str(exc.detail),
            "retry_after": getattr(exc, "retry_after", 60),
        },
        headers={
            "Retry-After": str(getattr(exc, "retry_after", 60)),
            "X-RateLimit-Limit": request.headers.get("X-RateLimit-Limit", "100"),
            "X-RateLimit-Remaining": "0",
        },
    )


def configure_rate_limiting(
    app: FastAPI,
    default_limits: Optional[list[str]] = None,
    storage_uri: str = "memory://",
    key_func: Optional[Callable] = None,
) -> Limiter:
    """Configure rate limiting for the FastAPI application.

    Args:
        app: FastAPI application instance.
        default_limits: Default rate limits (e.g., ["100/minute", "1000/hour"]).
        storage_uri: Storage backend URI (memory://, redis://host:port).
        key_func: Function to extract client identifier from request.

    Returns:
        Configured Limiter instance.

    Example:
        limiter = configure_rate_limiting(
            app,
            default_limits=["100/minute"],
            storage_uri="redis://localhost:6379"
        )
    """
    global limiter

    # Create new limiter with configuration
    limiter = Limiter(
        key_func=key_func or get_client_identifier,
        default_limits=default_limits or ["100/minute"],
        storage_uri=storage_uri,
    )

    # Add limiter to app state
    app.state.limiter = limiter

    # Add middleware
    app.add_middleware(SlowAPIMiddleware)

    # Add exception handler
    app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

    logger.info(f"Rate limiting configured with limits: {default_limits or ['100/minute']}")

    return limiter


# Decorator shortcuts for common rate limits
def limit_per_minute(calls: int) -> Callable:
    """Create a rate limit decorator for N calls per minute.

    Args:
        calls: Number of calls allowed per minute.

    Returns:
        Rate limit decorator.

    Example:
        @app.get("/api/resource")
        @limit_per_minute(10)
        async def get_resource():
            ...
    """
    return limiter.limit(f"{calls}/minute")


def limit_per_hour(calls: int) -> Callable:
    """Create a rate limit decorator for N calls per hour.

    Args:
        calls: Number of calls allowed per hour.

    Returns:
        Rate limit decorator.
    """
    return limiter.limit(f"{calls}/hour")


def limit_per_day(calls: int) -> Callable:
    """Create a rate limit decorator for N calls per day.

    Args:
        calls: Number of calls allowed per day.

    Returns:
        Rate limit decorator.
    """
    return limiter.limit(f"{calls}/day")


# Pre-defined limit tiers
RATE_LIMIT_TIERS = {
    "free": ["60/minute", "1000/day"],
    "basic": ["120/minute", "5000/day"],
    "pro": ["300/minute", "20000/day"],
    "enterprise": ["1000/minute", "100000/day"],
}


def get_tier_limit(tier: str) -> Callable:
    """Get rate limit decorator for a specific tier.

    Args:
        tier: Rate limit tier (free, basic, pro, enterprise).

    Returns:
        Rate limit decorator.

    Example:
        @app.get("/api/resource")
        @get_tier_limit("pro")
        async def get_resource():
            ...
    """
    limits = RATE_LIMIT_TIERS.get(tier, RATE_LIMIT_TIERS["free"])
    return limiter.limit(limits[0])
