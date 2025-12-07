"""Health check endpoints."""

import logging
from datetime import datetime

from fastapi import APIRouter

from ..config import get_settings
from ..models import HealthResponse

router = APIRouter(prefix="/health", tags=["Health"])
logger = logging.getLogger(__name__)


async def check_database_health() -> str:
    """Check database connectivity."""
    from ..database import is_database_configured, get_engine
    from sqlalchemy import text

    if not is_database_configured():
        return "not configured"

    engine = get_engine()
    if engine is None:
        return "not initialized"

    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return "connected"
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return "error"


@router.get("", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """
    Health check endpoint for Azure App Service.

    Returns the current health status of the application,
    including database and storage connectivity status.
    """
    settings = get_settings()

    # Check database connectivity
    db_status = await check_database_health()

    # Check storage connectivity
    storage_status = (
        "connected" if settings.azure_storage_connection_string else "not configured"
    )

    return HealthResponse(
        status="healthy",
        version=settings.app_version,
        timestamp=datetime.utcnow(),
        database=db_status,
        storage=storage_status,
    )


@router.get("/ready")
async def readiness_check() -> dict:
    """
    Readiness check for Kubernetes/container orchestration.

    Returns 200 if the application is ready to receive traffic.
    """
    # Check if database is ready (if configured)
    db_status = await check_database_health()
    db_ready = db_status in ("connected", "not configured")

    return {"ready": db_ready}


@router.get("/live")
async def liveness_check() -> dict:
    """
    Liveness check for Kubernetes/container orchestration.

    Returns 200 if the application is alive.
    """
    return {"alive": True}
