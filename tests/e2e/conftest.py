"""Pytest configuration and fixtures for E2E tests."""

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
def e2e_base_url() -> str:
    """Get the base URL for E2E tests.

    Uses environment variable for deployed environments,
    falls back to TestClient for local testing.
    """
    return os.getenv("E2E_BASE_URL", "http://testserver")


@pytest.fixture(scope="session")
def e2e_api_key() -> str | None:
    """Get API key for authenticated E2E tests."""
    return os.getenv("E2E_API_KEY")


@pytest.fixture
def e2e_client() -> Generator[TestClient, None, None]:
    """Create a test client for E2E tests.

    For deployed environments, this would be replaced with
    an HTTP client pointing to the actual service.
    """
    with TestClient(app) as client:
        yield client


@pytest.fixture
def workflow_test_data() -> dict:
    """Test data for complete workflow scenarios."""
    return {
        "items": [
            {
                "name": "E2E Test Product A",
                "description": "First product for E2E testing",
                "price": 100.00,
                "quantity": 50,
            },
            {
                "name": "E2E Test Product B",
                "description": "Second product for E2E testing",
                "price": 200.00,
                "quantity": 30,
            },
            {
                "name": "E2E Test Product C",
                "description": "Third product for E2E testing",
                "price": 150.00,
                "quantity": 40,
            },
        ],
    }
