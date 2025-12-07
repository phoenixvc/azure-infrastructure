"""Database module for async SQLAlchemy integration."""

from .base import BaseRepository, UnitOfWork, DatabaseHealth
from .connection import (
    get_db,
    init_db,
    close_db,
    get_engine,
    is_database_configured,
)
from .models import Base, ItemModel
from .repository import ItemRepository

__all__ = [
    # Abstract interfaces
    "BaseRepository",
    "UnitOfWork",
    "DatabaseHealth",
    # Connection management
    "get_db",
    "init_db",
    "close_db",
    "get_engine",
    "is_database_configured",
    # SQLAlchemy models
    "Base",
    "ItemModel",
    # Repositories
    "ItemRepository",
]
