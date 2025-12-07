"""Unit tests for Pydantic models."""

import pytest
from pydantic import ValidationError

from src.api.app.models import (
    User,
    UserCreate,
    Item,
    ItemCreate,
    HealthResponse,
    ErrorResponse,
)


class TestUserModels:
    """Test suite for User models."""

    def test_user_create_valid(self):
        """Test creating a valid UserCreate model."""
        user = UserCreate(
            email="test@example.com",
            name="Test User",
            password="securepass123",
        )
        assert user.email == "test@example.com"
        assert user.name == "Test User"
        assert user.is_active is True

    def test_user_create_invalid_email(self):
        """Test that invalid email raises ValidationError."""
        with pytest.raises(ValidationError):
            UserCreate(
                email="not-an-email",
                name="Test User",
                password="securepass123",
            )

    def test_user_create_short_password(self):
        """Test that short password raises ValidationError."""
        with pytest.raises(ValidationError):
            UserCreate(
                email="test@example.com",
                name="Test User",
                password="short",
            )

    def test_user_create_empty_name(self):
        """Test that empty name raises ValidationError."""
        with pytest.raises(ValidationError):
            UserCreate(
                email="test@example.com",
                name="",
                password="securepass123",
            )

    def test_user_has_id_and_timestamps(self):
        """Test that User model has auto-generated id and timestamps."""
        user = User(email="test@example.com", name="Test User")
        assert user.id is not None
        assert user.created_at is not None


class TestItemModels:
    """Test suite for Item models."""

    def test_item_create_valid(self):
        """Test creating a valid ItemCreate model."""
        item = ItemCreate(
            name="Test Item",
            description="A test item",
            price=29.99,
            quantity=10,
        )
        assert item.name == "Test Item"
        assert item.price == 29.99
        assert item.quantity == 10

    def test_item_create_without_description(self):
        """Test creating item without optional description."""
        item = ItemCreate(name="Test Item", price=29.99)
        assert item.description is None
        assert item.quantity == 0

    def test_item_create_negative_price(self):
        """Test that negative price raises ValidationError."""
        with pytest.raises(ValidationError):
            ItemCreate(name="Test Item", price=-10.00)

    def test_item_create_negative_quantity(self):
        """Test that negative quantity raises ValidationError."""
        with pytest.raises(ValidationError):
            ItemCreate(name="Test Item", price=10.00, quantity=-5)

    def test_item_create_empty_name(self):
        """Test that empty name raises ValidationError."""
        with pytest.raises(ValidationError):
            ItemCreate(name="", price=10.00)

    def test_item_has_id_and_timestamps(self):
        """Test that Item model has auto-generated id and timestamps."""
        item = Item(name="Test Item", price=29.99)
        assert item.id is not None
        assert item.created_at is not None


class TestHealthResponse:
    """Test suite for HealthResponse model."""

    def test_health_response_defaults(self):
        """Test HealthResponse with default values."""
        health = HealthResponse(version="1.0.0")
        assert health.status == "healthy"
        assert health.version == "1.0.0"
        assert health.database == "unknown"
        assert health.storage == "unknown"

    def test_health_response_custom_values(self):
        """Test HealthResponse with custom values."""
        health = HealthResponse(
            status="degraded",
            version="2.0.0",
            database="connected",
            storage="connected",
        )
        assert health.status == "degraded"
        assert health.database == "connected"


class TestErrorResponse:
    """Test suite for ErrorResponse model."""

    def test_error_response_minimal(self):
        """Test ErrorResponse with minimal data."""
        error = ErrorResponse(error="Not Found", status_code=404)
        assert error.error == "Not Found"
        assert error.status_code == 404
        assert error.detail is None

    def test_error_response_with_detail(self):
        """Test ErrorResponse with detail."""
        error = ErrorResponse(
            error="Validation Error",
            detail="Field 'name' is required",
            status_code=422,
        )
        assert error.detail == "Field 'name' is required"
