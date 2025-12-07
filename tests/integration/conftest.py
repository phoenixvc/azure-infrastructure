"""Pytest configuration and fixtures for integration tests."""

import os
import pytest
from typing import Generator
from fastapi.testclient import TestClient

from src.api.app.main import app


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
