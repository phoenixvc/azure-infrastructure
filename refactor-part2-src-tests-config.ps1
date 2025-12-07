# ============================================================================
# Part 2: Source Code Templates + Tests + Config + Database
# ============================================================================
# Run from: C:\Users\smitj\repos\azure-infrastructure
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🔧 Part 2: Source Code + Tests + Config + Database" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Verify we're in the right place
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in azure-infrastructure repo" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 1. Create API Template (FastAPI)
# ============================================================================
Write-Host "`n📝 Creating API template (FastAPI)..." -ForegroundColor Yellow

@'
# API Template

FastAPI template for Azure App Service deployment.

---

## Structure

```
src/api/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   ├── config.py            # Configuration
│   ├── models.py            # Data models
│   └── routers/
│       ├── __init__.py
│       └── health.py        # Health check endpoint
├── Dockerfile
├── requirements.txt
└── README.md
```

---

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn app.main:app --reload --port 8000

# Test health endpoint
curl http://localhost:8000/health
```

---

## Docker Build

```bash
docker build -t myapi:latest .
docker run -p 8000:8000 myapi:latest
```

---

## Azure Deployment

```bash
# Deploy to App Service
az webapp up --name nl-prod-rooivalk-api-euw --resource-group nl-prod-rooivalk-rg-euw --runtime "PYTHON:3.11"
```

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host/db` |
| `AZURE_STORAGE_CONNECTION_STRING` | Storage connection | From Key Vault |
| `LOG_LEVEL` | Logging level | `INFO` |

---

## Health Check

The API exposes a `/health` endpoint for Azure health checks:

```json
{
"status": "healthy",
"version": "1.0.0",
"timestamp": "2025-12-07T02:52:00Z"
}
```
'@ | Out-File -FilePath "src/api/README.md" -Encoding UTF8
Write-Host "  ✓ Created src/api/README.md" -ForegroundColor Green

@'
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app/ ./app/

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
'@ | Out-File -FilePath "src/api/Dockerfile" -Encoding UTF8
Write-Host "  ✓ Created src/api/Dockerfile" -ForegroundColor Green

@'
# FastAPI API Template
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
pydantic-settings==2.1.0
python-dotenv==1.0.0

# Database
asyncpg==0.29.0
sqlalchemy==2.0.25

# Azure SDK
azure-identity==1.15.0
azure-keyvault-secrets==4.7.0
azure-storage-blob==12.19.0

# Monitoring
opencensus-ext-azure==1.1.13
'@ | Out-File -FilePath "src/api/requirements.txt" -Encoding UTF8
Write-Host "  ✓ Created src/api/requirements.txt" -ForegroundColor Green

# ============================================================================
# 2. Create Azure Functions Template
# ============================================================================
Write-Host "`n📝 Creating Azure Functions template..." -ForegroundColor Yellow

@'
# Azure Functions Template

Python Azure Functions template for event-driven processing.

---

## Structure

```
src/functions/
├── function_app.py          # Function definitions
├── host.json                # Function host configuration
├── local.settings.json      # Local development settings
├── requirements.txt
└── README.md
```

---

## Local Development

```bash
# Install Azure Functions Core Tools
# https://learn.microsoft.com/azure/azure-functions/functions-run-local

# Install dependencies
pip install -r requirements.txt

# Run locally
func start
```

---

## Function Types

### HTTP Trigger
```python
@app.route(route="hello")
def hello(req: func.HttpRequest) -> func.HttpResponse:
  return func.HttpResponse("Hello, World!")
```

### Timer Trigger
```python
@app.schedule(schedule="0 */5 * * * *", arg_name="timer")
def scheduled_job(timer: func.TimerRequest) -> None:
  logging.info("Timer trigger executed")
```

### Blob Trigger
```python
@app.blob_trigger(arg_name="blob", path="uploads/{name}", connection="AzureWebJobsStorage")
def process_blob(blob: func.InputStream):
  logging.info(f"Processing blob: {blob.name}")
```

---

## Azure Deployment

```bash
# Deploy to Function App
func azure functionapp publish nl-prod-rooivalk-func-euw
```

---

## Environment Variables

Configure in Azure Portal or via CLI:

```bash
az functionapp config appsettings set \
--name nl-prod-rooivalk-func-euw \
--resource-group nl-prod-rooivalk-rg-euw \
--settings "DATABASE_URL=<connection-string>"
```
'@ | Out-File -FilePath "src/functions/README.md" -Encoding UTF8
Write-Host "  ✓ Created src/functions/README.md" -ForegroundColor Green

@'
{
"version": "2.0",
"logging": {
  "applicationInsights": {
    "samplingSettings": {
      "isEnabled": true,
      "maxTelemetryItemsPerSecond": 20
    }
  }
},
"extensionBundle": {
  "id": "Microsoft.Azure.Functions.ExtensionBundle",
  "version": "[4.*, 5.0.0)"
}
}
'@ | Out-File -FilePath "src/functions/host.json" -Encoding UTF8
Write-Host "  ✓ Created src/functions/host.json" -ForegroundColor Green

@'
# Azure Functions Python
azure-functions==1.18.0

# Database
asyncpg==0.29.0
sqlalchemy==2.0.25

# Azure SDK
azure-identity==1.15.0
azure-keyvault-secrets==4.7.0
azure-storage-blob==12.19.0
'@ | Out-File -FilePath "src/functions/requirements.txt" -Encoding UTF8
Write-Host "  ✓ Created src/functions/requirements.txt" -ForegroundColor Green

# ============================================================================
# 3. Create Worker Template
# ============================================================================
Write-Host "`n📝 Creating Worker template..." -ForegroundColor Yellow

@'
# Background Worker Template

Python background worker for long-running tasks.

---

## Structure

```
src/worker/
├── worker/
│   ├── __init__.py
│   ├── main.py              # Worker entry point
│   ├── config.py            # Configuration
│   └── tasks/
│       ├── __init__.py
│       └── example_task.py  # Task definitions
├── Dockerfile
├── requirements.txt
└── README.md
```

---

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run worker
python -m worker.main
```

---

## Docker Build

```bash
docker build -t myworker:latest .
docker run myworker:latest
```

---

## Azure Deployment

Deploy as Azure Container Instance or Container App:

```bash
# Deploy to Container Instance
az container create \
--resource-group nl-prod-rooivalk-rg-euw \
--name nl-prod-rooivalk-worker-euw \
--image myregistry.azurecr.io/worker:latest \
--cpu 1 --memory 1
```

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `QUEUE_CONNECTION_STRING` | Service Bus connection | From Key Vault |
| `DATABASE_URL` | PostgreSQL connection string | From Key Vault |
| `LOG_LEVEL` | Logging level | `INFO` |
'@ | Out-File -FilePath "src/worker/README.md" -Encoding UTF8
Write-Host "  ✓ Created src/worker/README.md" -ForegroundColor Green

@'
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY worker/ ./worker/

# Run worker
CMD ["python", "-m", "worker.main"]
'@ | Out-File -FilePath "src/worker/Dockerfile" -Encoding UTF8
Write-Host "  ✓ Created src/worker/Dockerfile" -ForegroundColor Green

@'
# Background Worker
python-dotenv==1.0.0

# Azure SDK
azure-identity==1.15.0
azure-servicebus==7.11.4
azure-storage-queue==12.9.0

# Database
asyncpg==0.29.0
sqlalchemy==2.0.25

# Task processing
celery==5.3.4
redis==5.0.1
'@ | Out-File -FilePath "src/worker/requirements.txt" -Encoding UTF8
Write-Host "  ✓ Created src/worker/requirements.txt" -ForegroundColor Green

# ============================================================================
# 4. Create Test Structure
# ============================================================================
Write-Host "`n📝 Creating test structure..." -ForegroundColor Yellow

@'
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
'@ | Out-File -FilePath "tests/unit/README.md" -Encoding UTF8
Write-Host "  ✓ Created tests/unit/README.md" -ForegroundColor Green

@'
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
'@ | Out-File -FilePath "tests/integration/README.md" -Encoding UTF8
Write-Host "  ✓ Created tests/integration/README.md" -ForegroundColor Green

@'
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
'@ | Out-File -FilePath "tests/e2e/README.md" -Encoding UTF8
Write-Host "  ✓ Created tests/e2e/README.md" -ForegroundColor Green

# ============================================================================
# 5. Create Configuration Templates
# ============================================================================
Write-Host "`n📝 Creating configuration templates..." -ForegroundColor Yellow

@'
{
"org": "nl",
"env": "dev",
"project": "rooivalk",
"region": "euw",
"azure": {
  "subscription_id": "00000000-0000-0000-0000-000000000000",
  "resource_group": "nl-dev-rooivalk-rg-euw",
  "location": "westeurope"
},
"features": {
  "enable_auth": false,
  "enable_caching": false,
  "debug_mode": true
},
"database": {
  "host": "nl-dev-rooivalk-db-euw.postgres.database.azure.com",
  "port": 5432,
  "name": "rooivalk_dev"
},
"logging": {
  "level": "DEBUG"
}
}
'@ | Out-File -FilePath "config/dev.json" -Encoding UTF8
Write-Host "  ✓ Created config/dev.json" -ForegroundColor Green

@'
{
"org": "nl",
"env": "staging",
"project": "rooivalk",
"region": "euw",
"azure": {
  "subscription_id": "00000000-0000-0000-0000-000000000000",
  "resource_group": "nl-staging-rooivalk-rg-euw",
  "location": "westeurope"
},
"features": {
  "enable_auth": true,
  "enable_caching": true,
  "debug_mode": false
},
"database": {
  "host": "nl-staging-rooivalk-db-euw.postgres.database.azure.com",
  "port": 5432,
  "name": "rooivalk_staging"
},
"logging": {
  "level": "INFO"
}
}
'@ | Out-File -FilePath "config/staging.json" -Encoding UTF8
Write-Host "  ✓ Created config/staging.json" -ForegroundColor Green

@'
{
"org": "nl",
"env": "prod",
"project": "rooivalk",
"region": "euw",
"azure": {
  "subscription_id": "00000000-0000-0000-0000-000000000000",
  "resource_group": "nl-prod-rooivalk-rg-euw",
  "location": "westeurope"
},
"features": {
  "enable_auth": true,
  "enable_caching": true,
  "debug_mode": false
},
"database": {
  "host": "nl-prod-rooivalk-db-euw.postgres.database.azure.com",
  "port": 5432,
  "name": "rooivalk_prod"
},
"logging": {
  "level": "WARNING"
}
}
'@ | Out-File -FilePath "config/prod.json" -Encoding UTF8
Write-Host "  ✓ Created config/prod.json" -ForegroundColor Green

@'
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
'@ | Out-File -FilePath "config/README.md" -Encoding UTF8
Write-Host "  ✓ Created config/README.md" -ForegroundColor Green

# ============================================================================
# 6. Create Database Structure
# ============================================================================
Write-Host "`n📝 Creating database structure..." -ForegroundColor Yellow

@'
-- Migration: 001_initial_schema.sql
-- Description: Initial database schema
-- Date: 2025-12-07

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
'@ | Out-File -FilePath "db/migrations/001_initial_schema.sql" -Encoding UTF8
Write-Host "  ✓ Created db/migrations/001_initial_schema.sql" -ForegroundColor Green

@'
-- Seed data for development environment

INSERT INTO users (email, name) VALUES
  ('test1@example.com', 'Test User 1'),
  ('test2@example.com', 'Test User 2'),
  ('admin@example.com', 'Admin User');
'@ | Out-File -FilePath "db/seeds/dev_data.sql" -Encoding UTF8
Write-Host "  ✓ Created db/seeds/dev_data.sql" -ForegroundColor Green

@'
# Database

Database migrations and seed data.

---

## Running Migrations

```bash
# Connect to database
psql -h nl-dev-rooivalk-db-euw.postgres.database.azure.com \
   -U dbadmin \
   -d rooivalk_dev

# Run migration
\i db/migrations/001_initial_schema.sql
```

---

## Seeding Data

```bash
psql -h localhost -U postgres -d rooivalk_dev -f db/seeds/dev_data.sql
```

---

## Best Practices

- Always use migrations (never manual schema changes)
- Test migrations on dev before prod
- Version control all migrations
'@ | Out-File -FilePath "db/README.md" -Encoding UTF8
Write-Host "  ✓ Created db/README.md" -ForegroundColor Green

# ============================================================================
# 7. Git Commit Part 2
# ============================================================================
Write-Host "`n📤 Committing Part 2 changes..." -ForegroundColor Yellow

git add .
git commit -m "feat: Part 2 - Source code templates, tests, config, database

- Added source code templates (API, Functions, Worker)
- Created test structure (unit, integration, e2e)
- Added configuration templates (dev, staging, prod)
- Created database structure (migrations, seeds)"

Write-Host "`n✅ Part 2 Complete!" -ForegroundColor Green
Write-Host "`n📍 Next: Run refactor-part3-tools-cicd-docs.ps1" -ForegroundColor Cyan