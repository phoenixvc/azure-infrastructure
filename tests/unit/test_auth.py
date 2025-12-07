"""Unit tests for authentication middleware."""

import os
import pytest
from fastapi import FastAPI, Depends
from fastapi.testclient import TestClient

import sys
from pathlib import Path

# Add src to path for imports
src_path = Path(__file__).parent.parent.parent / "src" / "api"
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

from app.middleware.auth import APIKeyAuth, get_api_key, verify_api_key
from app.config import get_settings


class TestAPIKeyAuth:
    """Test suite for API key authentication."""

    @pytest.fixture
    def test_app(self):
        """Create a test app with protected endpoints."""
        app = FastAPI()
        auth = APIKeyAuth()

        @app.get("/public")
        async def public_route():
            return {"message": "Public"}

        @app.get("/protected")
        async def protected_route(api_key: str = Depends(auth)):
            return {"message": "Protected", "api_key": api_key}

        return app

    @pytest.fixture
    def auth_client(self, test_app):
        """Create test client."""
        return TestClient(test_app)

    def test_public_route_accessible(self, auth_client):
        """Test that public routes are accessible without auth."""
        response = auth_client.get("/public")
        assert response.status_code == 200
        assert response.json()["message"] == "Public"

    def test_protected_route_without_api_key_configured(
        self, auth_client, monkeypatch
    ):
        """Test protected route when no API key is configured (dev mode)."""
        # Ensure no API key is configured
        monkeypatch.setenv("API_KEY", "")
        get_settings.cache_clear()

        response = auth_client.get("/protected")
        assert response.status_code == 200

    def test_protected_route_with_valid_api_key_header(
        self, auth_client, monkeypatch
    ):
        """Test protected route with valid API key in header."""
        test_api_key = "test-api-key-12345"
        monkeypatch.setenv("API_KEY", test_api_key)
        get_settings.cache_clear()

        response = auth_client.get(
            "/protected",
            headers={"X-API-Key": test_api_key}
        )
        assert response.status_code == 200
        assert response.json()["api_key"] == test_api_key

    def test_protected_route_with_valid_api_key_query(
        self, auth_client, monkeypatch
    ):
        """Test protected route with valid API key in query param."""
        test_api_key = "test-api-key-12345"
        monkeypatch.setenv("API_KEY", test_api_key)
        get_settings.cache_clear()

        response = auth_client.get(f"/protected?api_key={test_api_key}")
        assert response.status_code == 200
        assert response.json()["api_key"] == test_api_key

    def test_protected_route_with_invalid_api_key(
        self, auth_client, monkeypatch
    ):
        """Test protected route with invalid API key."""
        monkeypatch.setenv("API_KEY", "correct-key")
        get_settings.cache_clear()

        response = auth_client.get(
            "/protected",
            headers={"X-API-Key": "wrong-key"}
        )
        assert response.status_code == 401
        assert "Invalid" in response.json()["detail"]

    def test_protected_route_missing_api_key(
        self, auth_client, monkeypatch
    ):
        """Test protected route without API key when required."""
        monkeypatch.setenv("API_KEY", "required-key")
        get_settings.cache_clear()

        response = auth_client.get("/protected")
        assert response.status_code == 401

    def test_header_takes_precedence_over_query(
        self, auth_client, monkeypatch
    ):
        """Test that header API key takes precedence over query."""
        test_api_key = "header-key"
        monkeypatch.setenv("API_KEY", test_api_key)
        get_settings.cache_clear()

        response = auth_client.get(
            "/protected?api_key=query-key",
            headers={"X-API-Key": test_api_key}
        )
        assert response.status_code == 200
        assert response.json()["api_key"] == test_api_key


class TestAPIKeyAuthAutoError:
    """Test APIKeyAuth with auto_error=False."""

    @pytest.fixture
    def test_app_no_error(self):
        """Create test app with non-error auth."""
        app = FastAPI()
        auth = APIKeyAuth(auto_error=False)

        @app.get("/optional-auth")
        async def optional_auth_route(api_key: str = Depends(auth)):
            if api_key:
                return {"authenticated": True, "api_key": api_key}
            return {"authenticated": False}

        return app

    @pytest.fixture
    def client_no_error(self, test_app_no_error):
        """Create test client."""
        return TestClient(test_app_no_error)

    def test_optional_auth_without_key(self, client_no_error, monkeypatch):
        """Test optional auth returns None without key."""
        monkeypatch.setenv("API_KEY", "some-key")
        get_settings.cache_clear()

        response = client_no_error.get("/optional-auth")
        assert response.status_code == 200
        assert response.json()["authenticated"] is False

    def test_optional_auth_with_valid_key(self, client_no_error, monkeypatch):
        """Test optional auth returns key when valid."""
        test_key = "valid-key"
        monkeypatch.setenv("API_KEY", test_key)
        get_settings.cache_clear()

        response = client_no_error.get(
            "/optional-auth",
            headers={"X-API-Key": test_key}
        )
        assert response.status_code == 200
        assert response.json()["authenticated"] is True
