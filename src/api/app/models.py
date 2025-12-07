"""Pydantic models for request/response schemas."""

from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4

from pydantic import BaseModel, Field, EmailStr


class HealthResponse(BaseModel):
    """Health check response model."""

    status: str = "healthy"
    version: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    database: str = "unknown"
    storage: str = "unknown"


class UserBase(BaseModel):
    """Base user model."""

    email: EmailStr
    name: str = Field(..., min_length=1, max_length=100)
    is_active: bool = True


class UserCreate(UserBase):
    """User creation model."""

    password: str = Field(..., min_length=8)


class User(UserBase):
    """User response model."""

    id: UUID = Field(default_factory=uuid4)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None

    class Config:
        """Pydantic configuration."""

        from_attributes = True


class ItemBase(BaseModel):
    """Base item model."""

    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    price: float = Field(..., ge=0)
    quantity: int = Field(default=0, ge=0)


class ItemCreate(ItemBase):
    """Item creation model."""

    pass


class Item(ItemBase):
    """Item response model."""

    id: UUID = Field(default_factory=uuid4)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None

    class Config:
        """Pydantic configuration."""

        from_attributes = True


class ErrorResponse(BaseModel):
    """Error response model."""

    error: str
    detail: Optional[str] = None
    status_code: int
