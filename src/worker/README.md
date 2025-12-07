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
