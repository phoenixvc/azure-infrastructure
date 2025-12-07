# Example: NeuralLiquid Rooivalk Platform

Complete implementation example for NeuralLiquid's Rooivalk AI platform.

---

## Project Details

- **Organization:** nl (NeuralLiquid)
- **Project:** rooivalk
- **Environments:** dev, staging, prod
- **Primary Region:** euw (West Europe)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Resource Group: nl-prod-rooivalk-rg-euw               │ │
│  │                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │
│  │  │  API Service │  │  Function App│  │  PostgreSQL  │ │ │
│  │  │  (FastAPI)   │  │  (Python)    │  │  Database    │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │ │
│  │                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │
│  │  │  Storage     │  │  Key Vault   │  │  Log         │ │ │
│  │  │  Account     │  │              │  │  Analytics   │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Resource Naming

| Resource | Name |
|----------|------|
| Resource Group | `nl-prod-rooivalk-rg-euw` |
| API Service | `nl-prod-rooivalk-api-euw` |
| Function App | `nl-prod-rooivalk-func-euw` |
| PostgreSQL | `nl-prod-rooivalk-db-euw` |
| Storage Account | `nlprodrooivalkstorageeuw` |
| Key Vault | `nl-prod-rooivalk-kv-euw` |
| Log Analytics | `nl-prod-rooivalk-log-euw` |

---

## Deployment

### **1. Deploy Infrastructure**

```bash
az deployment sub create \
--location westeurope \
--template-file infra/examples/nl-rooivalk.bicep \
--parameters dbAdminPassword="<secure-password>"
```

### **2. Deploy API**

```bash
cd src/api
az webapp up \
--name nl-prod-rooivalk-api-euw \
--resource-group nl-prod-rooivalk-rg-euw \
--runtime "PYTHON:3.11"
```

### **3. Deploy Functions**

```bash
cd src/functions
func azure functionapp publish nl-prod-rooivalk-func-euw
```

---

## Configuration

Environment variables stored in Key Vault:

- `DATABASE_URL` - PostgreSQL connection string
- `STORAGE_CONNECTION_STRING` - Storage account connection
- `API_KEY` - External API keys

---

## Monitoring

- **Application Insights** - Application telemetry
- **Log Analytics** - Centralized logging
- **Azure Monitor** - Alerts and dashboards

---

## CI/CD

GitHub Actions workflows:
- `.github/workflows/ci-api.yml` - API testing and deployment
- `.github/workflows/ci-functions.yml` - Functions testing and deployment

---

## Related Resources

- [Infrastructure Code](../../infra/examples/nl-rooivalk.bicep)
- [API Source](../../src/api/)
- [Functions Source](../../src/functions/)
