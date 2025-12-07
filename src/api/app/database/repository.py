"""Repository pattern for database operations."""

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from .models import ItemModel
from ..models import Item, ItemCreate


class ItemRepository:
    """Repository for Item CRUD operations."""

    def __init__(self, session: AsyncSession):
        """Initialize repository with database session."""
        self.session = session

    async def get_all(self, skip: int = 0, limit: int = 100) -> List[Item]:
        """
        Get all items with pagination.

        Args:
            skip: Number of records to skip
            limit: Maximum number of records to return

        Returns:
            List of Item objects
        """
        query = select(ItemModel).offset(skip).limit(limit).order_by(ItemModel.created_at.desc())
        result = await self.session.execute(query)
        items = result.scalars().all()
        return [self._to_pydantic(item) for item in items]

    async def get_by_id(self, item_id: UUID) -> Optional[Item]:
        """
        Get an item by ID.

        Args:
            item_id: UUID of the item

        Returns:
            Item if found, None otherwise
        """
        query = select(ItemModel).where(ItemModel.id == item_id)
        result = await self.session.execute(query)
        item = result.scalar_one_or_none()
        return self._to_pydantic(item) if item else None

    async def create(self, item_data: ItemCreate) -> Item:
        """
        Create a new item.

        Args:
            item_data: Item creation data

        Returns:
            Created Item
        """
        db_item = ItemModel(
            name=item_data.name,
            description=item_data.description,
            price=item_data.price,
            quantity=item_data.quantity,
        )
        self.session.add(db_item)
        await self.session.flush()
        await self.session.refresh(db_item)
        return self._to_pydantic(db_item)

    async def update(self, item_id: UUID, item_data: ItemCreate) -> Optional[Item]:
        """
        Update an existing item.

        Args:
            item_id: UUID of the item to update
            item_data: New item data

        Returns:
            Updated Item if found, None otherwise
        """
        query = select(ItemModel).where(ItemModel.id == item_id)
        result = await self.session.execute(query)
        db_item = result.scalar_one_or_none()

        if not db_item:
            return None

        db_item.name = item_data.name
        db_item.description = item_data.description
        db_item.price = item_data.price
        db_item.quantity = item_data.quantity

        await self.session.flush()
        await self.session.refresh(db_item)
        return self._to_pydantic(db_item)

    async def delete(self, item_id: UUID) -> bool:
        """
        Delete an item.

        Args:
            item_id: UUID of the item to delete

        Returns:
            True if deleted, False if not found
        """
        query = select(ItemModel).where(ItemModel.id == item_id)
        result = await self.session.execute(query)
        db_item = result.scalar_one_or_none()

        if not db_item:
            return False

        await self.session.delete(db_item)
        await self.session.flush()
        return True

    @staticmethod
    def _to_pydantic(db_item: ItemModel) -> Item:
        """Convert SQLAlchemy model to Pydantic model."""
        return Item(
            id=db_item.id,
            name=db_item.name,
            description=db_item.description,
            price=db_item.price,
            quantity=db_item.quantity,
            created_at=db_item.created_at,
            updated_at=db_item.updated_at,
        )
