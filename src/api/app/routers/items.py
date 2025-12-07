"""Items CRUD endpoints."""

from typing import List
from uuid import UUID, uuid4

from fastapi import APIRouter, HTTPException, status

from ..models import Item, ItemCreate

router = APIRouter(prefix="/items", tags=["Items"])

# In-memory storage for demo purposes
# Replace with database in production
_items_db: dict[UUID, Item] = {}


@router.get("", response_model=List[Item])
async def list_items(skip: int = 0, limit: int = 100) -> List[Item]:
    """
    List all items with pagination.

    Args:
        skip: Number of items to skip (default: 0)
        limit: Maximum number of items to return (default: 100)

    Returns:
        List of items
    """
    items = list(_items_db.values())
    return items[skip : skip + limit]


@router.post("", response_model=Item, status_code=status.HTTP_201_CREATED)
async def create_item(item: ItemCreate) -> Item:
    """
    Create a new item.

    Args:
        item: Item data to create

    Returns:
        Created item with generated ID
    """
    new_item = Item(
        id=uuid4(),
        name=item.name,
        description=item.description,
        price=item.price,
        quantity=item.quantity,
    )
    _items_db[new_item.id] = new_item
    return new_item


@router.get("/{item_id}", response_model=Item)
async def get_item(item_id: UUID) -> Item:
    """
    Get a specific item by ID.

    Args:
        item_id: UUID of the item to retrieve

    Returns:
        Item if found

    Raises:
        HTTPException: 404 if item not found
    """
    if item_id not in _items_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with ID {item_id} not found",
        )
    return _items_db[item_id]


@router.put("/{item_id}", response_model=Item)
async def update_item(item_id: UUID, item: ItemCreate) -> Item:
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
    if item_id not in _items_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with ID {item_id} not found",
        )

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


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(item_id: UUID) -> None:
    """
    Delete an item.

    Args:
        item_id: UUID of the item to delete

    Raises:
        HTTPException: 404 if item not found
    """
    if item_id not in _items_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with ID {item_id} not found",
        )
    del _items_db[item_id]
