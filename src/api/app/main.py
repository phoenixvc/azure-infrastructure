"""FastAPI Application Entry Point."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .routers import health_router, items_router
from .observability import init_telemetry, instrument_fastapi
from .middleware.rate_limit import configure_rate_limiting

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler for startup/shutdown events."""
    from .database import init_db, close_db, is_database_configured

    # Startup
    logger.info("Starting application...")
    settings = get_settings()
    logger.info(f"App: {settings.app_name} v{settings.app_version}")
    logger.info(f"Debug mode: {settings.debug}")

    # Initialize OpenTelemetry
    init_telemetry(
        service_name=settings.app_name,
        service_version=settings.app_version,
        app_insights_connection_string=settings.applicationinsights_connection_string,
        enable_console_export=settings.debug,
    )
    instrument_fastapi(app)
    logger.info("OpenTelemetry instrumentation enabled")

    # Initialize database if configured
    if is_database_configured():
        await init_db()
    else:
        logger.info("No database configured, using in-memory storage")

    yield

    # Shutdown
    logger.info("Shutting down application...")
    if is_database_configured():
        await close_db()


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="Azure Infrastructure API - A reference implementation for Azure deployments",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    # Configure CORS
    origins = settings.cors_origins.split(",") if settings.cors_origins else ["*"]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Configure rate limiting
    configure_rate_limiting(
        app,
        default_limits=["100/minute", "1000/hour"],
    )

    # Register routers with API versioning
    # Health endpoints at root level (for Azure health probes)
    app.include_router(health_router)

    # Versioned API endpoints
    app.include_router(items_router, prefix="/api/v1")

    @app.get("/")
    async def root():
        """Root endpoint returning API information."""
        return {
            "name": settings.app_name,
            "version": settings.app_version,
            "docs": "/docs",
            "health": "/health",
            "api": "/api/v1",
        }

    return app


# Create application instance
app = create_app()
