"""E2E performance tests."""

import pytest
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from fastapi.testclient import TestClient


class TestPerformance:
    """Performance tests for API endpoints."""

    def test_health_check_response_time(self, e2e_client: TestClient):
        """Test that health check responds within acceptable time."""
        max_response_time_ms = 500  # 500ms threshold

        start_time = time.time()
        response = e2e_client.get("/health")
        end_time = time.time()

        response_time_ms = (end_time - start_time) * 1000

        assert response.status_code == 200
        assert response_time_ms < max_response_time_ms, (
            f"Health check took {response_time_ms:.2f}ms, "
            f"expected < {max_response_time_ms}ms"
        )

    def test_list_items_response_time(self, e2e_client: TestClient):
        """Test that listing items responds within acceptable time."""
        max_response_time_ms = 1000  # 1 second threshold

        start_time = time.time()
        response = e2e_client.get("/items")
        end_time = time.time()

        response_time_ms = (end_time - start_time) * 1000

        assert response.status_code == 200
        assert response_time_ms < max_response_time_ms, (
            f"List items took {response_time_ms:.2f}ms, "
            f"expected < {max_response_time_ms}ms"
        )

    def test_create_item_response_time(self, e2e_client: TestClient):
        """Test that creating an item responds within acceptable time."""
        max_response_time_ms = 1000  # 1 second threshold

        item_data = {
            "name": "Performance Test Item",
            "description": "Testing response time",
            "price": 99.99,
            "quantity": 10,
        }

        start_time = time.time()
        response = e2e_client.post("/items", json=item_data)
        end_time = time.time()

        response_time_ms = (end_time - start_time) * 1000

        assert response.status_code == 201
        assert response_time_ms < max_response_time_ms, (
            f"Create item took {response_time_ms:.2f}ms, "
            f"expected < {max_response_time_ms}ms"
        )

        # Cleanup
        item_id = response.json()["id"]
        e2e_client.delete(f"/items/{item_id}")

    def test_concurrent_health_checks(self, e2e_client: TestClient):
        """Test handling concurrent health check requests."""
        num_requests = 10
        max_total_time_s = 5  # 5 seconds for all requests

        def make_health_request():
            response = e2e_client.get("/health")
            return response.status_code

        start_time = time.time()

        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = [
                executor.submit(make_health_request) for _ in range(num_requests)
            ]
            results = [future.result() for future in as_completed(futures)]

        end_time = time.time()
        total_time = end_time - start_time

        # All requests should succeed
        assert all(status == 200 for status in results)

        # Total time should be reasonable
        assert total_time < max_total_time_s, (
            f"Concurrent requests took {total_time:.2f}s, "
            f"expected < {max_total_time_s}s"
        )

    def test_concurrent_crud_operations(self, e2e_client: TestClient):
        """Test handling concurrent CRUD operations."""
        num_operations = 5

        def create_item(index: int) -> dict:
            item_data = {
                "name": f"Concurrent Item {index}",
                "description": f"Created in concurrent test {index}",
                "price": 10.0 * index,
                "quantity": index,
            }
            response = e2e_client.post("/items", json=item_data)
            return {"status": response.status_code, "data": response.json()}

        # Create items concurrently
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(create_item, i) for i in range(1, num_operations + 1)]
            results = [future.result() for future in as_completed(futures)]

        # All creates should succeed
        assert all(r["status"] == 201 for r in results)

        # Cleanup
        for result in results:
            item_id = result["data"]["id"]
            e2e_client.delete(f"/items/{item_id}")


class TestReliability:
    """Reliability tests for API endpoints."""

    def test_repeated_requests_consistency(self, e2e_client: TestClient):
        """Test that repeated requests return consistent results."""
        num_requests = 10
        responses = []

        for _ in range(num_requests):
            response = e2e_client.get("/health")
            responses.append(response.json())

        # All responses should have the same status
        statuses = [r["status"] for r in responses]
        assert all(status == "healthy" for status in statuses)

        # All responses should have the same version
        versions = [r["version"] for r in responses]
        assert len(set(versions)) == 1

    def test_api_stability_under_load(self, e2e_client: TestClient):
        """Test API stability under sustained load."""
        num_iterations = 20
        created_items = []
        errors = []

        # Sustained create/read/delete cycle
        for i in range(num_iterations):
            try:
                # Create
                item_data = {
                    "name": f"Stability Test Item {i}",
                    "price": 10.0,
                    "quantity": 1,
                }
                create_resp = e2e_client.post("/items", json=item_data)
                assert create_resp.status_code == 201

                item_id = create_resp.json()["id"]

                # Read
                get_resp = e2e_client.get(f"/items/{item_id}")
                assert get_resp.status_code == 200

                # Delete
                del_resp = e2e_client.delete(f"/items/{item_id}")
                assert del_resp.status_code == 204

            except AssertionError as e:
                errors.append(f"Iteration {i}: {str(e)}")

        # No errors should occur
        assert len(errors) == 0, f"Errors occurred: {errors}"
