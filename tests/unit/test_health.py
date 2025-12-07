"""Unit tests for health check endpoints."""

import pytest
from fastapi.testclient import TestClient


class TestHealthEndpoints:
    """Test suite for health check endpoints."""

    def test_health_check_returns_200(self, client: TestClient):
        """Test that health check returns 200 status."""
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_check_returns_correct_structure(self, client: TestClient):
        """Test that health check returns expected JSON structure."""
        response = client.get("/health")
        data = response.json()

        assert "status" in data
        assert "version" in data
        assert "timestamp" in data
        assert "database" in data
        assert "storage" in data

    def test_health_check_status_is_healthy(self, client: TestClient):
        """Test that health check status is 'healthy'."""
        response = client.get("/health")
        data = response.json()

        assert data["status"] == "healthy"

    def test_readiness_check_returns_200(self, client: TestClient):
        """Test that readiness check returns 200 status."""
        response = client.get("/health/ready")
        assert response.status_code == 200

    def test_readiness_check_returns_ready_true(self, client: TestClient):
        """Test that readiness check returns ready: true."""
        response = client.get("/health/ready")
        data = response.json()

        assert data["ready"] is True

    def test_liveness_check_returns_200(self, client: TestClient):
        """Test that liveness check returns 200 status."""
        response = client.get("/health/live")
        assert response.status_code == 200

    def test_liveness_check_returns_alive_true(self, client: TestClient):
        """Test that liveness check returns alive: true."""
        response = client.get("/health/live")
        data = response.json()

        assert data["alive"] is True
