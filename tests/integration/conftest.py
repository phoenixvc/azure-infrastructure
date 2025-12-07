"""Pytest configuration and fixtures for integration tests."""

import os
import sys
from pathlib import Path
from typing import Generator

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


@pytest.fixture(scope="session")
def test_database_url() -> str:
    """Get test database URL from environment or use default."""
    return os.getenv(
        "TEST_DATABASE_URL",
        "postgresql://test:test@localhost:5432/test_db",
    )


@pytest.fixture(scope="session")
def test_storage_connection() -> str:
    """Get test storage connection string from environment or use default."""
    return os.getenv(
        "TEST_STORAGE_CONNECTION_STRING",
        "DefaultEndpointsProtocol=https;AccountName=test;AccountKey=test==;EndpointSuffix=core.windows.net",
    )


@pytest.fixture
def integration_client() -> Generator[TestClient, None, None]:
    """Create a test client for integration tests."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def sample_items() -> list[dict]:
    """Sample items for bulk operations testing."""
    return [
        {"name": f"Item {i}", "description": f"Description {i}", "price": i * 10.0, "quantity": i}
        for i in range(1, 6)
    ]
