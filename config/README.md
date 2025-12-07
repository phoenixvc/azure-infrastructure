# Configuration

Environment-specific configuration files.

---

## Usage

### Python (Pydantic Settings)

```python
from pydantic_settings import BaseSettings
import json

class Settings(BaseSettings):
  org: str
  env: str
  project: str
  
  @classmethod
  def from_json(cls, env: str):
      with open(f"config/{env}.json") as f:
          return cls(**json.load(f))

settings = Settings.from_json("dev")
```

---

## Best Practices

- Store secrets in Azure Key Vault
- Never commit secrets to config files
- Use environment variables for overrides
