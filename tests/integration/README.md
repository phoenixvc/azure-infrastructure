# Integration Tests

Integration tests for component interactions.

---

## Running Tests

```bash
# Run integration tests (requires Azure resources)
pytest tests/integration/ -v

# Run with specific markers
pytest tests/integration/ -m "database" -v
```

---

## Example Test

```python
import pytest
from app.database import get_db_connection

@pytest.mark.integration
@pytest.mark.database
async def test_database_connection():
  async with get_db_connection() as conn:
      result = await conn.fetchval("SELECT 1")
      assert result == 1
```
