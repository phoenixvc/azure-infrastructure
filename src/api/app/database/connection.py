"""Database connection management with async SQLAlchemy."""

import logging
from typing import AsyncGenerator, Optional

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import NullPool

from ..config import get_settings

logger = logging.getLogger(__name__)

# Global engine and session factory
_engine: Optional[AsyncEngine] = None
_async_session_factory: Optional[async_sessionmaker[AsyncSession]] = None


def is_database_configured() -> bool:
    """Check if database URL is configured."""
    settings = get_settings()
    return bool(settings.database_url)


def get_engine() -> Optional[AsyncEngine]:
    """Get the current database engine."""
    return _engine


async def init_db() -> None:
    """Initialize the database connection and create tables."""
    global _engine, _async_session_factory

    settings = get_settings()

    if not settings.database_url:
        logger.info("No DATABASE_URL configured, using in-memory storage")
        return

    # Convert postgresql:// to postgresql+asyncpg:// if needed
    db_url = settings.database_url
    if db_url.startswith("postgresql://"):
        db_url = db_url.replace("postgresql://", "postgresql+asyncpg://", 1)
    elif db_url.startswith("postgres://"):
        db_url = db_url.replace("postgres://", "postgresql+asyncpg://", 1)

    logger.info("Initializing database connection...")

    _engine = create_async_engine(
        db_url,
        pool_size=settings.database_pool_size,
        max_overflow=settings.database_max_overflow,
        pool_pre_ping=True,
        echo=settings.debug,
    )

    _async_session_factory = async_sessionmaker(
        bind=_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=False,
    )

    # Create tables
    from .models import Base

    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    logger.info("Database initialized successfully")


async def close_db() -> None:
    """Close the database connection."""
    global _engine, _async_session_factory

    if _engine:
        logger.info("Closing database connection...")
        await _engine.dispose()
        _engine = None
        _async_session_factory = None
        logger.info("Database connection closed")


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Get a database session.

    Yields:
        AsyncSession: Database session for use in requests

    Raises:
        RuntimeError: If database is not initialized
    """
    if _async_session_factory is None:
        raise RuntimeError(
            "Database not initialized. "
            "Call init_db() first or configure DATABASE_URL."
        )

    async with _async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
