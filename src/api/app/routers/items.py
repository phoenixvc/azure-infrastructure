"""Items CRUD endpoints."""

from typing import List, Optional
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, status

from ..models import Item, ItemCreate

router = APIRouter(prefix="/items", tags=["Items"])

# In-memory storage fallback when database is not configured
_items_db: dict[UUID, Item] = {}


async def get_optional_db():
    """Get database session if configured, None otherwise."""
    from ..database import is_database_configured, get_db

    if not is_database_configured():
        yield None
        return

    async for session in get_db():
        yield session


# --- In-Memory Operations (fallback) ---


async def _list_items_memory(skip: int, limit: int) -> List[Item]:
    """List items from in-memory storage."""
    items = list(_items_db.values())
    return items[skip : skip + limit]


async def _create_item_memory(item: ItemCreate) -> Item:
    """Create item in in-memory storage."""
    new_item = Item(
        id=uuid4(),
        name=item.name,
        description=item.description,
        price=item.price,
        quantity=item.quantity,
    )
    _items_db[new_item.id] = new_item
    return new_item


async def _get_item_memory(item_id: UUID) -> Optional[Item]:
    """Get item from in-memory storage."""
    return _items_db.get(item_id)


async def _update_item_memory(item_id: UUID, item: ItemCreate) -> Optional[Item]:
    """Update item in in-memory storage."""
    if item_id not in _items_db:
        return None
    existing = _items_db[item_id]
    updated_item = Item(
        id=existing.id,
        name=item.name,
        description=item.description,
        price=item.price,
        quantity=item.quantity,
        created_at=existing.created_at,
    )
    _items_db[item_id] = updated_item
    return updated_item


async def _delete_item_memory(item_id: UUID) -> bool:
    """Delete item from in-memory storage."""
    if item_id not in _items_db:
        return False
    del _items_db[item_id]
    return True


# --- Database Operations ---


async def _list_items_db(session, skip: int, limit: int) -> List[Item]:
    """List items from database."""
    from ..database import ItemRepository

    repo = ItemRepository(session)
    return await repo.get_all(skip=skip, limit=limit)


async def _create_item_db(session, item: ItemCreate) -> Item:
    """Create item in database."""
    from ..database import ItemRepository

    repo = ItemRepository(session)
    return await repo.create(item)


async def _get_item_db(session, item_id: UUID) -> Optional[Item]:
    """Get item from database."""
    from ..database import ItemRepository

    repo = ItemRepository(session)
    return await repo.get_by_id(item_id)


async def _update_item_db(session, item_id: UUID, item: ItemCreate) -> Optional[Item]:
    """Update item in database."""
    from ..database import ItemRepository

    repo = ItemRepository(session)
    return await repo.update(item_id, item)


async def _delete_item_db(session, item_id: UUID) -> bool:
    """Delete item from database."""
    from ..database import ItemRepository

    repo = ItemRepository(session)
    return await repo.delete(item_id)


# --- API Endpoints ---


@router.get("", response_model=List[Item])
async def list_items(
    skip: int = 0,
    limit: int = 100,
    db=Depends(get_optional_db),
) -> List[Item]:
    """
    List all items with pagination.

    Args:
        skip: Number of items to skip (default: 0)
        limit: Maximum number of items to return (default: 100)

    Returns:
        List of items
    """
    if db is not None:
        return await _list_items_db(db, skip, limit)
    return await _list_items_memory(skip, limit)


@router.post("", response_model=Item, status_code=status.HTTP_201_CREATED)
async def create_item(
    item: ItemCreate,
    db=Depends(get_optional_db),
) -> Item:
    """
    Create a new item.

    Args:
        item: Item data to create

    Returns:
        Created item with generated ID
    """
    if db is not None:
        return await _create_item_db(db, item)
    return await _create_item_memory(item)


@router.get("/{item_id}", response_model=Item)
async def get_item(
    item_id: UUID,
    db=Depends(get_optional_db),
) -> Item:
    """
    Get a specific item by ID.

    Args:
        item_id: UUID of the item to retrieve

    Returns:
        Item if found

    Raises:
        HTTPException: 404 if item not found
    """
    if db is not None:
        item = await _get_item_db(db, item_id)
    else:
        item = await _get_item_memory(item_id)

    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with ID {item_id} not found",
        )
    return item


@router.put("/{item_id}", response_model=Item)
async def update_item(
    item_id: UUID,
    item: ItemCreate,
    db=Depends(get_optional_db),
) -> Item:
    """
    Update an existing item.

    Args:
        item_id: UUID of the item to update
        item: New item data

    Returns:
        Updated item

    Raises:
        HTTPException: 404 if item not found
    """
    if db is not None:
        updated = await _update_item_db(db, item_id, item)
    else:
        updated = await _update_item_memory(item_id, item)

    if updated is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with ID {item_id} not found",
        )
    return updated


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(
    item_id: UUID,
    db=Depends(get_optional_db),
) -> None:
    """
    Delete an item.

    Args:
        item_id: UUID of the item to delete

    Raises:
        HTTPException: 404 if item not found
    """
    if db is not None:
        deleted = await _delete_item_db(db, item_id)
    else:
        deleted = await _delete_item_memory(item_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with ID {item_id} not found",
        )
