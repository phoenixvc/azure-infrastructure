"""Authentication middleware for API key and optional JWT support."""

import logging
from typing import Optional

from fastapi import Depends, HTTPException, Security, status
from fastapi.security import APIKeyHeader, APIKeyQuery

from ..config import get_settings

logger = logging.getLogger(__name__)

# API Key can be provided in header or query parameter
api_key_header = APIKeyHeader(
    name="X-API-Key",
    auto_error=False,
    description="API Key authentication header",
)
api_key_query = APIKeyQuery(
    name="api_key",
    auto_error=False,
    description="API Key authentication query parameter",
)


async def get_api_key(
    api_key_header_value: Optional[str] = Security(api_key_header),
    api_key_query_value: Optional[str] = Security(api_key_query),
) -> Optional[str]:
    """
    Extract API key from header or query parameter.

    Args:
        api_key_header_value: API key from X-API-Key header
        api_key_query_value: API key from api_key query parameter

    Returns:
        API key if provided, None otherwise
    """
    return api_key_header_value or api_key_query_value


async def verify_api_key(
    api_key: Optional[str] = Depends(get_api_key),
) -> Optional[str]:
    """
    Verify the API key if authentication is required.

    This dependency checks if API_KEY is configured in settings.
    If configured, the provided key must match.
    If not configured, authentication is bypassed (development mode).

    Args:
        api_key: API key from request

    Returns:
        Verified API key or None if auth not required

    Raises:
        HTTPException: 401 if auth required but key missing/invalid
    """
    settings = get_settings()

    # If no API key configured, skip authentication (development mode)
    if not settings.api_key:
        return None

    # API key required but not provided
    if not api_key:
        logger.warning("API key required but not provided")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    # Verify API key matches
    if api_key != settings.api_key:
        logger.warning("Invalid API key provided")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    return api_key


class APIKeyAuth:
    """
    API Key authentication class for use as a dependency.

    Can be used to protect specific routes or route groups.

    Example:
        ```python
        from app.middleware import APIKeyAuth

        auth = APIKeyAuth()

        @router.get("/protected")
        async def protected_route(api_key: str = Depends(auth)):
            return {"message": "Authenticated!"}
        ```
    """

    def __init__(self, auto_error: bool = True):
        """
        Initialize API Key authentication.

        Args:
            auto_error: If True, raise 401 on auth failure.
                       If False, return None instead.
        """
        self.auto_error = auto_error

    async def __call__(
        self,
        api_key: Optional[str] = Depends(get_api_key),
    ) -> Optional[str]:
        """
        Verify the API key.

        Args:
            api_key: API key from request

        Returns:
            Verified API key or None

        Raises:
            HTTPException: 401 if auto_error and auth fails
        """
        settings = get_settings()

        # If no API key configured, skip authentication
        if not settings.api_key:
            return None

        # Check if key provided and valid
        if api_key and api_key == settings.api_key:
            return api_key

        # Auth failed
        if self.auto_error:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or missing API key",
                headers={"WWW-Authenticate": "ApiKey"},
            )

        return None


# Optional: Rate limiting can be added here in the future
# class RateLimiter:
#     """Rate limiting middleware for API endpoints."""
#     pass
