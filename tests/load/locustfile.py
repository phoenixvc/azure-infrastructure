"""
Locust load testing configuration for Azure Infrastructure API.

Usage:
    # Run locally against development server
    locust -f tests/load/locustfile.py --host http://localhost:8000

    # Run with web UI
    locust -f tests/load/locustfile.py --host http://localhost:8000

    # Run headless with specific user count and spawn rate
    locust -f tests/load/locustfile.py --host http://localhost:8000 \
        --headless --users 100 --spawn-rate 10 --run-time 5m

    # Run against Azure deployment
    locust -f tests/load/locustfile.py --host https://your-api.azurewebsites.net \
        --headless --users 50 --spawn-rate 5 --run-time 10m
"""

import os
import random
from uuid import uuid4

from locust import HttpUser, task, between, events


class APIUser(HttpUser):
    """
    Simulates a typical API user performing CRUD operations.

    This user class models realistic usage patterns:
    - Frequent health checks (monitoring)
    - Read-heavy workload (70% reads, 30% writes)
    - Occasional bulk operations
    """

    # Wait between 1-3 seconds between tasks (simulates think time)
    wait_time = between(1, 3)

    # Store created item IDs for read/update/delete operations
    created_items = []

    def on_start(self):
        """Initialize user session."""
        # Get API key from environment if configured
        self.api_key = os.getenv("LOAD_TEST_API_KEY")
        self.headers = {}
        if self.api_key:
            self.headers["X-API-Key"] = self.api_key

    @task(10)
    def health_check(self):
        """Check API health - high frequency for monitoring scenarios."""
        self.client.get("/health", headers=self.headers)

    @task(5)
    def list_items(self):
        """List all items - common read operation."""
        self.client.get("/api/v1/items", headers=self.headers)

    @task(5)
    def list_items_paginated(self):
        """List items with pagination - tests query parameters."""
        skip = random.randint(0, 10)
        limit = random.randint(5, 20)
        self.client.get(
            f"/api/v1/items?skip={skip}&limit={limit}",
            headers=self.headers,
        )

    @task(3)
    def create_item(self):
        """Create a new item - write operation."""
        item_data = {
            "name": f"Load Test Item {uuid4().hex[:8]}",
            "description": "Created during load testing",
            "price": round(random.uniform(10.0, 1000.0), 2),
            "quantity": random.randint(1, 100),
        }

        with self.client.post(
            "/api/v1/items",
            json=item_data,
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code == 201:
                item_id = response.json().get("id")
                if item_id:
                    self.created_items.append(item_id)
                response.success()
            else:
                response.failure(f"Failed to create item: {response.status_code}")

    @task(3)
    def get_item(self):
        """Get a specific item - read operation."""
        if self.created_items:
            item_id = random.choice(self.created_items)
            with self.client.get(
                f"/api/v1/items/{item_id}",
                headers=self.headers,
                catch_response=True,
            ) as response:
                if response.status_code == 200:
                    response.success()
                elif response.status_code == 404:
                    # Item might have been deleted
                    self.created_items.remove(item_id)
                    response.success()
                else:
                    response.failure(f"Unexpected status: {response.status_code}")

    @task(2)
    def update_item(self):
        """Update an existing item - write operation."""
        if self.created_items:
            item_id = random.choice(self.created_items)
            updated_data = {
                "name": f"Updated Item {uuid4().hex[:8]}",
                "description": "Updated during load testing",
                "price": round(random.uniform(10.0, 1000.0), 2),
                "quantity": random.randint(1, 100),
            }

            with self.client.put(
                f"/api/v1/items/{item_id}",
                json=updated_data,
                headers=self.headers,
                catch_response=True,
            ) as response:
                if response.status_code == 200:
                    response.success()
                elif response.status_code == 404:
                    self.created_items.remove(item_id)
                    response.success()
                else:
                    response.failure(f"Failed to update: {response.status_code}")

    @task(1)
    def delete_item(self):
        """Delete an item - cleanup operation."""
        if self.created_items:
            item_id = self.created_items.pop()

            with self.client.delete(
                f"/api/v1/items/{item_id}",
                headers=self.headers,
                catch_response=True,
            ) as response:
                if response.status_code in (204, 404):
                    response.success()
                else:
                    response.failure(f"Failed to delete: {response.status_code}")

    def on_stop(self):
        """Cleanup created items when user stops."""
        for item_id in self.created_items:
            self.client.delete(
                f"/api/v1/items/{item_id}",
                headers=self.headers,
            )
        self.created_items.clear()


class HealthCheckUser(HttpUser):
    """
    Simulates monitoring/health check traffic.

    Useful for testing health endpoint performance under load.
    """

    wait_time = between(0.5, 1)

    @task
    def health_check(self):
        """Continuous health checks."""
        self.client.get("/health")

    @task
    def readiness_check(self):
        """Kubernetes readiness probe simulation."""
        self.client.get("/health/ready")

    @task
    def liveness_check(self):
        """Kubernetes liveness probe simulation."""
        self.client.get("/health/live")


class BurstUser(HttpUser):
    """
    Simulates burst traffic patterns.

    Models scenarios like flash sales or viral content.
    """

    wait_time = between(0.1, 0.5)  # Very fast requests

    def on_start(self):
        """Initialize burst user."""
        self.api_key = os.getenv("LOAD_TEST_API_KEY")
        self.headers = {}
        if self.api_key:
            self.headers["X-API-Key"] = self.api_key

    @task(5)
    def rapid_list(self):
        """Rapid listing - simulates heavy browsing."""
        self.client.get("/api/v1/items", headers=self.headers)

    @task(3)
    def rapid_health(self):
        """Rapid health checks - monitoring under load."""
        self.client.get("/health", headers=self.headers)


# Event hooks for custom reporting


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Log when test starts."""
    print("=" * 60)
    print("Load test starting...")
    print(f"Target host: {environment.host}")
    print("=" * 60)


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Log when test stops."""
    print("=" * 60)
    print("Load test completed!")
    print("=" * 60)


@events.request.add_listener
def on_request(request_type, name, response_time, response_length, **kwargs):
    """Custom request logging (optional - can be noisy)."""
    # Uncomment for detailed logging:
    # print(f"{request_type} {name} - {response_time}ms")
    pass
