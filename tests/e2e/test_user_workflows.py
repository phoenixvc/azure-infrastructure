"""E2E tests for complete user workflows."""

import pytest
from fastapi.testclient import TestClient


class TestInventoryManagementWorkflow:
    """E2E tests for inventory management workflow.

    Simulates a user managing product inventory:
    1. Check system health
    2. Add new products
    3. View product catalog
    4. Update product details
    5. Remove products
    """

    def test_complete_inventory_workflow(
        self, e2e_client: TestClient, workflow_test_data: dict
    ):
        """Test complete inventory management workflow."""
        created_ids = []

        # Step 1: Verify system is healthy
        health_response = e2e_client.get("/health")
        assert health_response.status_code == 200
        assert health_response.json()["status"] == "healthy"

        # Step 2: Add products to inventory
        for item_data in workflow_test_data["items"]:
            response = e2e_client.post("/items", json=item_data)
            assert response.status_code == 201

            created_item = response.json()
            assert created_item["name"] == item_data["name"]
            assert created_item["price"] == item_data["price"]
            created_ids.append(created_item["id"])

        # Step 3: View product catalog
        list_response = e2e_client.get("/items")
        assert list_response.status_code == 200
        items = list_response.json()

        # Verify all products are in catalog
        catalog_ids = [item["id"] for item in items]
        for created_id in created_ids:
            assert created_id in catalog_ids

        # Step 4: Update product details (simulate price change)
        first_item_id = created_ids[0]
        original_item = e2e_client.get(f"/items/{first_item_id}").json()

        updated_data = {
            "name": original_item["name"],
            "description": "Updated description - On Sale!",
            "price": original_item["price"] * 0.8,  # 20% discount
            "quantity": original_item["quantity"],
        }
        update_response = e2e_client.put(f"/items/{first_item_id}", json=updated_data)
        assert update_response.status_code == 200
        assert update_response.json()["price"] == updated_data["price"]

        # Step 5: Remove a product (sold out/discontinued)
        last_item_id = created_ids[-1]
        delete_response = e2e_client.delete(f"/items/{last_item_id}")
        assert delete_response.status_code == 204

        # Verify product removed from catalog
        get_deleted = e2e_client.get(f"/items/{last_item_id}")
        assert get_deleted.status_code == 404

        # Cleanup remaining items
        for item_id in created_ids[:-1]:  # Already deleted last one
            e2e_client.delete(f"/items/{item_id}")


class TestAPIDiscoveryWorkflow:
    """E2E tests for API discovery workflow.

    Simulates a developer exploring the API:
    1. Access root endpoint
    2. View API documentation
    3. Check OpenAPI spec
    4. Verify health endpoints
    """

    def test_api_discovery_workflow(self, e2e_client: TestClient):
        """Test API discovery workflow for new developers."""
        # Step 1: Access root endpoint for API info
        root_response = e2e_client.get("/")
        assert root_response.status_code == 200
        root_data = root_response.json()

        assert "name" in root_data
        assert "version" in root_data
        assert "docs" in root_data

        # Step 2: Access Swagger documentation
        docs_url = root_data["docs"]
        docs_response = e2e_client.get(docs_url)
        assert docs_response.status_code == 200
        assert "text/html" in docs_response.headers["content-type"]

        # Step 3: Access OpenAPI specification
        openapi_response = e2e_client.get("/openapi.json")
        assert openapi_response.status_code == 200
        openapi_data = openapi_response.json()

        assert "openapi" in openapi_data
        assert "paths" in openapi_data
        assert "/health" in openapi_data["paths"]
        assert "/items" in openapi_data["paths"]

        # Step 4: Verify health endpoints
        health_url = root_data["health"]
        health_response = e2e_client.get(health_url)
        assert health_response.status_code == 200

        # Check all health endpoints
        ready_response = e2e_client.get("/health/ready")
        live_response = e2e_client.get("/health/live")

        assert ready_response.status_code == 200
        assert live_response.status_code == 200


class TestErrorHandlingWorkflow:
    """E2E tests for error handling scenarios.

    Simulates various error conditions a user might encounter:
    1. Resource not found
    2. Invalid input data
    3. Duplicate operations
    """

    def test_resource_not_found_workflow(self, e2e_client: TestClient):
        """Test handling of non-existent resources."""
        from uuid import uuid4

        # Try to get non-existent item
        fake_id = uuid4()
        get_response = e2e_client.get(f"/items/{fake_id}")
        assert get_response.status_code == 404

        # Try to update non-existent item
        update_data = {"name": "Test", "price": 10.0}
        update_response = e2e_client.put(f"/items/{fake_id}", json=update_data)
        assert update_response.status_code == 404

        # Try to delete non-existent item
        delete_response = e2e_client.delete(f"/items/{fake_id}")
        assert delete_response.status_code == 404

    def test_invalid_input_workflow(self, e2e_client: TestClient):
        """Test handling of invalid input data."""
        # Invalid item: empty name
        invalid_item_1 = {"name": "", "price": 10.0}
        response_1 = e2e_client.post("/items", json=invalid_item_1)
        assert response_1.status_code == 422

        # Invalid item: negative price
        invalid_item_2 = {"name": "Test Item", "price": -10.0}
        response_2 = e2e_client.post("/items", json=invalid_item_2)
        assert response_2.status_code == 422

        # Invalid item: missing required field
        invalid_item_3 = {"description": "No name or price"}
        response_3 = e2e_client.post("/items", json=invalid_item_3)
        assert response_3.status_code == 422

    def test_idempotency_workflow(self, e2e_client: TestClient):
        """Test that operations are handled correctly when repeated."""
        # Create an item
        item_data = {
            "name": "Idempotency Test Item",
            "description": "Testing repeated operations",
            "price": 50.0,
            "quantity": 10,
        }
        create_response = e2e_client.post("/items", json=item_data)
        assert create_response.status_code == 201
        item_id = create_response.json()["id"]

        # Delete item
        delete_1 = e2e_client.delete(f"/items/{item_id}")
        assert delete_1.status_code == 204

        # Try to delete again - should return 404
        delete_2 = e2e_client.delete(f"/items/{item_id}")
        assert delete_2.status_code == 404
