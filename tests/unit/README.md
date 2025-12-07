# Unit Tests

Unit tests for individual components.

---

## Running Tests

```bash
# Install pytest
pip install pytest pytest-asyncio pytest-cov

# Run unit tests
pytest tests/unit/ -v

# Run with coverage
pytest tests/unit/ --cov=app --cov-report=html
```

---

## Example Test

```python
import pytest
from app.models import User

def test_user_creation():
  user = User(name="Test User", email="test@example.com")
  assert user.name == "Test User"
  assert user.email == "test@example.com"

@pytest.mark.asyncio
async def test_async_function():
  result = await some_async_function()
  assert result is not None
```
