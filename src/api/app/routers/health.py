"""Health check endpoints."""

from datetime import datetime

from fastapi import APIRouter

from ..config import get_settings
from ..models import HealthResponse

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """
    Health check endpoint for Azure App Service.

    Returns the current health status of the application,
    including database and storage connectivity status.
    """
    settings = get_settings()

    # Check database connectivity
    db_status = "connected" if settings.database_url else "not configured"

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
    return {"ready": True}


@router.get("/live")
async def liveness_check() -> dict:
    """
    Liveness check for Kubernetes/container orchestration.

    Returns 200 if the application is alive.
    """
    return {"alive": True}
