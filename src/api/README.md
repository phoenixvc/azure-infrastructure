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
