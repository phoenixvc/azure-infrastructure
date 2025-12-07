"""Integration tests for API endpoints."""

import pytest
from fastapi.testclient import TestClient


class TestAPIIntegration:
    """Integration tests for the complete API flow."""

    def test_root_endpoint_returns_api_info(self, integration_client: TestClient):
        """Test that root endpoint returns API information."""
        response = integration_client.get("/")
        assert response.status_code == 200

        data = response.json()
        assert "name" in data
        assert "version" in data
        assert "docs" in data
        assert "health" in data

    def test_openapi_schema_is_accessible(self, integration_client: TestClient):
        """Test that OpenAPI schema is accessible."""
        response = integration_client.get("/openapi.json")
        assert response.status_code == 200

        data = response.json()
        assert "openapi" in data
        assert "info" in data
        assert "paths" in data

    def test_docs_endpoint_is_accessible(self, integration_client: TestClient):
        """Test that Swagger docs are accessible."""
        response = integration_client.get("/docs")
        assert response.status_code == 200
        assert "text/html" in response.headers["content-type"]

    def test_redoc_endpoint_is_accessible(self, integration_client: TestClient):
        """Test that ReDoc is accessible."""
        response = integration_client.get("/redoc")
        assert response.status_code == 200
        assert "text/html" in response.headers["content-type"]


class TestItemsCRUDIntegration:
    """Integration tests for complete CRUD operations on items."""

    def test_full_crud_lifecycle(self, integration_client: TestClient):
        """Test complete CRUD lifecycle: create, read, update, delete."""
        # Create
        item_data = {
            "name": "Integration Test Item",
            "description": "Created during integration test",
            "price": 99.99,
            "quantity": 5,
        }
        create_response = integration_client.post("/api/v1/items", json=item_data)
        assert create_response.status_code == 201
        created_item = create_response.json()
        item_id = created_item["id"]

        # Read
        get_response = integration_client.get(f"/api/v1/items/{item_id}")
        assert get_response.status_code == 200
        assert get_response.json()["name"] == item_data["name"]

        # Update
        updated_data = {**item_data, "name": "Updated Integration Item", "price": 149.99}
        update_response = integration_client.put(f"/api/v1/items/{item_id}", json=updated_data)
        assert update_response.status_code == 200
        assert update_response.json()["name"] == "Updated Integration Item"
        assert update_response.json()["price"] == 149.99

        # Verify update persisted
        verify_response = integration_client.get(f"/api/v1/items/{item_id}")
        assert verify_response.json()["name"] == "Updated Integration Item"

        # Delete
        delete_response = integration_client.delete(f"/api/v1/items/{item_id}")
        assert delete_response.status_code == 204

        # Verify deletion
        get_deleted = integration_client.get(f"/api/v1/items/{item_id}")
        assert get_deleted.status_code == 404

    def test_bulk_create_and_list(
        self, integration_client: TestClient, sample_items: list[dict]
    ):
        """Test creating multiple items and listing them."""
        created_ids = []

        # Create multiple items
        for item_data in sample_items:
            response = integration_client.post("/api/v1/items", json=item_data)
            assert response.status_code == 201
            created_ids.append(response.json()["id"])

        # List all items
        list_response = integration_client.get("/api/v1/items")
        assert list_response.status_code == 200
        items = list_response.json()

        # Verify all created items are in the list
        item_ids_in_list = [item["id"] for item in items]
        for created_id in created_ids:
            assert created_id in item_ids_in_list

        # Cleanup
        for item_id in created_ids:
            integration_client.delete(f"/api/v1/items/{item_id}")

    def test_pagination(self, integration_client: TestClient, sample_items: list[dict]):
        """Test list pagination with skip and limit."""
        created_ids = []

        # Create items
        for item_data in sample_items:
            response = integration_client.post("/api/v1/items", json=item_data)
            created_ids.append(response.json()["id"])

        # Test pagination
        page1 = integration_client.get("/api/v1/items?skip=0&limit=2")
        assert page1.status_code == 200
        assert len(page1.json()) <= 2

        page2 = integration_client.get("/api/v1/items?skip=2&limit=2")
        assert page2.status_code == 200

        # Cleanup
        for item_id in created_ids:
            integration_client.delete(f"/api/v1/items/{item_id}")


class TestHealthIntegration:
    """Integration tests for health check endpoints."""

    def test_health_endpoints_are_consistent(self, integration_client: TestClient):
        """Test that all health endpoints return consistent data."""
        health = integration_client.get("/health")
        ready = integration_client.get("/health/ready")
        live = integration_client.get("/health/live")

        assert health.status_code == 200
        assert ready.status_code == 200
        assert live.status_code == 200

        # All should indicate healthy state
        assert health.json()["status"] == "healthy"
        assert ready.json()["ready"] is True
        assert live.json()["alive"] is True
