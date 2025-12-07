# End-to-End Tests

End-to-end tests for complete user flows.

---

## Running Tests

```bash
# Run E2E tests (requires deployed environment)
pytest tests/e2e/ -v --env=staging
```

---

## Example Test

```python
import pytest
import httpx

@pytest.mark.e2e
async def test_complete_user_flow():
  base_url = "https://nl-staging-rooivalk-api-euw.azurewebsites.net"
  
  async with httpx.AsyncClient() as client:
      response = await client.get(f"{base_url}/health")
      assert response.status_code == 200
```
