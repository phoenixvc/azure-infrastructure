"""Pytest configuration and fixtures for unit tests."""

import pytest
from fastapi.testclient import TestClient

from src.api.app.main import app


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
