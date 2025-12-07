"""Unit tests for items CRUD endpoints."""

import pytest
from fastapi.testclient import TestClient
from uuid import uuid4


class TestItemsEndpoints:
    """Test suite for items CRUD endpoints."""

    def test_list_items_returns_200(self, client: TestClient):
        """Test that listing items returns 200 status."""
        response = client.get("/api/v1/items")
        assert response.status_code == 200

    def test_list_items_returns_list(self, client: TestClient):
        """Test that listing items returns a list."""
        response = client.get("/api/v1/items")
        data = response.json()

        assert isinstance(data, list)

    def test_create_item_returns_201(self, client: TestClient, sample_item_data: dict):
        """Test that creating an item returns 201 status."""
        response = client.post("/api/v1/items", json=sample_item_data)
        assert response.status_code == 201

    def test_create_item_returns_item_with_id(
        self, client: TestClient, sample_item_data: dict
    ):
        """Test that created item has an ID."""
        response = client.post("/api/v1/items", json=sample_item_data)
        data = response.json()

        assert "id" in data
        assert data["name"] == sample_item_data["name"]
        assert data["price"] == sample_item_data["price"]

    def test_create_item_with_invalid_data_returns_422(self, client: TestClient):
        """Test that creating item with invalid data returns 422."""
        invalid_data = {"name": "", "price": -10}
        response = client.post("/api/v1/items", json=invalid_data)
        assert response.status_code == 422

    def test_get_item_returns_200(self, client: TestClient, sample_item_data: dict):
        """Test that getting an existing item returns 200."""
        # First create an item
        create_response = client.post("/api/v1/items", json=sample_item_data)
        item_id = create_response.json()["id"]

        # Then get it
        response = client.get(f"/api/v1/items/{item_id}")
        assert response.status_code == 200

    def test_get_nonexistent_item_returns_404(self, client: TestClient):
        """Test that getting a nonexistent item returns 404."""
        fake_id = uuid4()
        response = client.get(f"/api/v1/items/{fake_id}")
        assert response.status_code == 404

    def test_update_item_returns_200(self, client: TestClient, sample_item_data: dict):
        """Test that updating an item returns 200."""
        # First create an item
        create_response = client.post("/api/v1/items", json=sample_item_data)
        item_id = create_response.json()["id"]

        # Update it
        updated_data = {**sample_item_data, "name": "Updated Item", "price": 39.99}
        response = client.put(f"/api/v1/items/{item_id}", json=updated_data)
        assert response.status_code == 200
        assert response.json()["name"] == "Updated Item"
        assert response.json()["price"] == 39.99

    def test_update_nonexistent_item_returns_404(
        self, client: TestClient, sample_item_data: dict
    ):
        """Test that updating a nonexistent item returns 404."""
        fake_id = uuid4()
        response = client.put(f"/api/v1/items/{fake_id}", json=sample_item_data)
        assert response.status_code == 404

    def test_delete_item_returns_204(self, client: TestClient, sample_item_data: dict):
        """Test that deleting an item returns 204."""
        # First create an item
        create_response = client.post("/api/v1/items", json=sample_item_data)
        item_id = create_response.json()["id"]

        # Delete it
        response = client.delete(f"/api/v1/items/{item_id}")
        assert response.status_code == 204

    def test_delete_nonexistent_item_returns_404(self, client: TestClient):
        """Test that deleting a nonexistent item returns 404."""
        fake_id = uuid4()
        response = client.delete(f"/api/v1/items/{fake_id}")
        assert response.status_code == 404

    def test_deleted_item_is_not_found(
        self, client: TestClient, sample_item_data: dict
    ):
        """Test that a deleted item cannot be retrieved."""
        # Create, delete, then try to get
        create_response = client.post("/api/v1/items", json=sample_item_data)
        item_id = create_response.json()["id"]

        client.delete(f"/api/v1/items/{item_id}")
        response = client.get(f"/api/v1/items/{item_id}")
        assert response.status_code == 404
