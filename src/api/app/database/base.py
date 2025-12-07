"""Abstract base classes for database operations.

These abstractions allow swapping database implementations without
changing business logic. Implementations can be:
- PostgreSQL (via SQLAlchemy async)
- In-memory (for testing/development)
- Other databases (MySQL, SQLite, Cosmos DB)
"""

from abc import ABC, abstractmethod
from typing import Generic, List, Optional, TypeVar
from uuid import UUID

from pydantic import BaseModel

# Type variables for generic repository
T = TypeVar("T", bound=BaseModel)  # Entity type
CreateT = TypeVar("CreateT", bound=BaseModel)  # Create DTO type


class BaseRepository(ABC, Generic[T, CreateT]):
    """Abstract base repository defining CRUD operations.

    This interface defines the contract for all repository implementations.
    Business logic depends on this abstraction, not concrete implementations.

    Example:
        ```python
        class ItemRepository(BaseRepository[Item, ItemCreate]):
            async def get_all(self, skip: int, limit: int) -> List[Item]:
                # PostgreSQL implementation
                ...

        class InMemoryItemRepository(BaseRepository[Item, ItemCreate]):
            async def get_all(self, skip: int, limit: int) -> List[Item]:
                # In-memory implementation
                ...
        ```
    """

    @abstractmethod
    async def get_all(self, skip: int = 0, limit: int = 100) -> List[T]:
        """Retrieve all entities with pagination.

        Args:
            skip: Number of records to skip (offset)
            limit: Maximum number of records to return

        Returns:
            List of entities
        """
        pass

    @abstractmethod
    async def get_by_id(self, entity_id: UUID) -> Optional[T]:
        """Retrieve a single entity by ID.

        Args:
            entity_id: UUID of the entity

        Returns:
            Entity if found, None otherwise
        """
        pass

    @abstractmethod
    async def create(self, data: CreateT) -> T:
        """Create a new entity.

        Args:
            data: Entity creation data

        Returns:
            Created entity with generated ID
        """
        pass

    @abstractmethod
    async def update(self, entity_id: UUID, data: CreateT) -> Optional[T]:
        """Update an existing entity.

        Args:
            entity_id: UUID of the entity to update
            data: Updated entity data

        Returns:
            Updated entity if found, None otherwise
        """
        pass

    @abstractmethod
    async def delete(self, entity_id: UUID) -> bool:
        """Delete an entity.

        Args:
            entity_id: UUID of the entity to delete

        Returns:
            True if deleted, False if not found
        """
        pass


class UnitOfWork(ABC):
    """Abstract unit of work for transaction management.

    Coordinates multiple repository operations within a single transaction.

    Example:
        ```python
        async with uow:
            item = await uow.items.create(item_data)
            await uow.audit_log.create(audit_entry)
            await uow.commit()
        ```
    """

    @abstractmethod
    async def __aenter__(self) -> "UnitOfWork":
        """Enter transaction context."""
        pass

    @abstractmethod
    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        """Exit transaction context, rolling back on exception."""
        pass

    @abstractmethod
    async def commit(self) -> None:
        """Commit the current transaction."""
        pass

    @abstractmethod
    async def rollback(self) -> None:
        """Rollback the current transaction."""
        pass


class DatabaseHealth(ABC):
    """Abstract interface for database health checking."""

    @abstractmethod
    async def is_healthy(self) -> bool:
        """Check if database is healthy and accepting connections.

        Returns:
            True if healthy, False otherwise
        """
        pass

    @abstractmethod
    async def get_status(self) -> dict:
        """Get detailed database status.

        Returns:
            Dict with status information (connections, latency, etc.)
        """
        pass
