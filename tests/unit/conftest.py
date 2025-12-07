"""Pytest configuration and fixtures for unit tests."""

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Add src to path for imports
src_path = Path(__file__).parent.parent.parent / "src" / "api"
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

from app.main import app
from app.routers import items


@pytest.fixture(autouse=True)
def clear_items_db():
    """Clear the in-memory items database before each test."""
    items._items_db.clear()
    yield
    items._items_db.clear()


@pytest.fixture
def client() -> TestClient:
    """Create a test client for the FastAPI application."""
    return TestClient(app)


@pytest.fixture
def sample_item_data() -> dict:
    """Sample item data for testing."""
    return {
        "name": "Test Item",
        "description": "A test item for unit testing",
        "price": 29.99,
        "quantity": 10,
    }


@pytest.fixture
def sample_user_data() -> dict:
    """Sample user data for testing."""
    return {
        "email": "test@example.com",
        "name": "Test User",
        "is_active": True,
        "password": "securepassword123",
    }
