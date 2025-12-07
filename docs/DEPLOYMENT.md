# Deployment Guide

Complete guide for deploying your Azure project from local development to production.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Application Deployment](#application-deployment)
- [Database Setup](#database-setup)
- [Secrets Management](#secrets-management)
- [Monitoring & Logging](#monitoring--logging)
- [Custom Domain & SSL](#custom-domain--ssl)
- [Environment Promotion](#environment-promotion)
- [Rollback Procedures](#rollback-procedures)
- [Disaster Recovery](#disaster-recovery)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

```bash
# Azure CLI (2.50+)
az --version

# Bicep CLI (0.20+)
az bicep version

# Docker (for containerization)
docker --version

# Python (3.11+)
python --version

# PostgreSQL client (for database management)
psql --version

# jq (for JSON parsing)
jq --version
```

### Installation (if needed)

```bash
# macOS
brew install azure-cli docker python@3.11 postgresql jq

# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt install docker.io python3.11 postgresql-client jq

# Windows (PowerShell)
winget install Microsoft.AzureCLI Docker.DockerDesktop Python.Python.3.11 jqlang.jq
```

### Azure Setup

```bash
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_NAME"

# Verify current context
az account show --output table

# Register required providers (first time only)
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.ContainerRegistry
```

### Verify Access

```bash
# Check you have required permissions
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --output table
```

---

## Infrastructure Deployment

### Project Structure

```
infra/
├── main.bicep              # Main orchestration template
├── modules/
│   ├── app-service.bicep   # App Service + Plan
│   ├── database.bicep      # PostgreSQL Flexible Server
│   ├── key-vault.bicep     # Key Vault
│   ├── monitoring.bicep    # App Insights + Log Analytics
│   ├── storage.bicep       # Storage Account
│   └── networking.bicep    # VNet + Subnets (optional)
└── parameters/
    ├── dev.bicepparam      # Development environment
    ├── staging.bicepparam  # Staging environment
    └── prod.bicepparam     # Production environment
```

### Step 1: Configure Parameters

**Development Environment** (`infra/parameters/dev.bicepparam`):

```bicep
using '../main.bicep'

param organizationName = 'yourorg'
param projectName = 'yourproject'
param environment = 'dev'
param location = 'westeurope'

// App Service Configuration
param appServiceConfig = {
  skuName: 'B1'
  skuCapacity: 1
  alwaysOn: false
  healthCheckPath: '/health'
}

// Database Configuration
param databaseConfig = {
  administratorLogin: 'dbadmin'
  skuName: 'Standard_B1ms'
  skuTier: 'Burstable'
  storageSizeGB: 32
  backupRetentionDays: 7
  geoRedundantBackup: false
  highAvailability: false
}

// Monitoring Configuration
param monitoringConfig = {
  logRetentionDays: 30
  enableDiagnostics: true
}

// Feature Flags
param enableRedisCache = false
param enableStaticWebApp = false
param enableVNetIntegration = false
```

**Production Environment** (`infra/parameters/prod.bicepparam`):

```bicep
using '../main.bicep'

param organizationName = 'yourorg'
param projectName = 'yourproject'
param environment = 'prod'
param location = 'westeurope'

// App Service Configuration
param appServiceConfig = {
  skuName: 'P1v3'
  skuCapacity: 2
  alwaysOn: true
  healthCheckPath: '/health'
}

// Database Configuration
param databaseConfig = {
  administratorLogin: 'dbadmin'
  skuName: 'Standard_D4s_v3'
  skuTier: 'GeneralPurpose'
  storageSizeGB: 128
  backupRetentionDays: 35
  geoRedundantBackup: true
  highAvailability: true
}

// Monitoring Configuration
param monitoringConfig = {
  logRetentionDays: 90
  enableDiagnostics: true
}

// Feature Flags
param enableRedisCache = true
param enableStaticWebApp = true
param enableVNetIntegration = true
```

### Step 2: Validate Bicep Templates

```bash
# Validate syntax
az bicep build --file infra/main.bicep

# Lint for best practices
az bicep lint --file infra/main.bicep

# Preview changes (What-If deployment)
az deployment sub what-if \
  --location westeurope \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam
```

### Step 3: Deploy Infrastructure

```bash
# Generate deployment name
DEPLOYMENT_NAME="deploy-$(date +%Y%m%d-%H%M%S)"

# Deploy to dev environment
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location westeurope \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam \
  --verbose

# Check deployment status
az deployment sub show \
  --name "$DEPLOYMENT_NAME" \
  --query "properties.provisioningState" -o tsv

# Get deployment outputs
az deployment sub show \
  --name "$DEPLOYMENT_NAME" \
  --query "properties.outputs" -o json | jq
```

### Step 4: Verify Resources

```bash
# Set variables from deployment outputs
RG_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.resourceGroupName.value" -o tsv)
APP_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.appServiceName.value" -o tsv)

# List all resources in resource group
az resource list --resource-group $RG_NAME --output table

# Verify App Service
az webapp show --name $APP_NAME --resource-group $RG_NAME --query "state" -o tsv

# Verify Database
az postgres flexible-server show \
  --resource-group $RG_NAME \
  --name $(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.databaseServerName.value" -o tsv) \
  --query "state" -o tsv
```

### Deployment Script (Automated)

Create `scripts/deploy-infra.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Configuration
ENVIRONMENT=${1:-dev}
LOCATION=${2:-westeurope}

echo "🚀 Deploying infrastructure to $ENVIRONMENT environment..."

# Validate parameters file exists
PARAMS_FILE="infra/parameters/${ENVIRONMENT}.bicepparam"
if [[ ! -f "$PARAMS_FILE" ]]; then
    echo "❌ Parameters file not found: $PARAMS_FILE"
    exit 1
fi

# Generate deployment name
DEPLOYMENT_NAME="deploy-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"

# Run What-If
echo "📋 Running What-If analysis..."
az deployment sub what-if \
  --location $LOCATION \
  --template-file infra/main.bicep \
  --parameters $PARAMS_FILE

# Prompt for confirmation
read -p "Continue with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Deploy
echo "🔄 Deploying..."
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location $LOCATION \
  --template-file infra/main.bicep \
  --parameters $PARAMS_FILE

# Verify
STATE=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.provisioningState" -o tsv)
if [[ "$STATE" == "Succeeded" ]]; then
    echo "✅ Deployment successful!"
    echo "📝 Deployment name: $DEPLOYMENT_NAME"
    
    # Export outputs
    az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs" -o json > "outputs-${ENVIRONMENT}.json"
    echo "📄 Outputs saved to outputs-${ENVIRONMENT}.json"
else
    echo "❌ Deployment failed with state: $STATE"
    exit 1
fi
```

---

## Application Deployment

### Option A: Direct Deployment (Quick Start)

Best for: Initial development, quick testing

```bash
cd src/api

# Install dependencies
pip install -r requirements.txt

# Deploy directly to App Service
az webapp up \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --runtime "PYTHON:3.11" \
  --sku B1

# Verify deployment
curl https://$APP_NAME.azurewebsites.net/health
```

### Option B: Docker Deployment (Recommended)

Best for: Consistent environments, production deployments

**Step 1: Create Dockerfile**

```dockerfile
# src/api/Dockerfile
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Production image
FROM python:3.11-slim

WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy wheels and install
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/*

# Copy application
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

**Step 2: Create .dockerignore**

```
# src/api/.dockerignore
__pycache__
*.pyc
*.pyo
.git
.gitignore
.env
.env.*
*.md
tests/
.pytest_cache/
.coverage
htmlcov/
.mypy_cache/
.ruff_cache/
```

**Step 3: Build and Test Locally**

```bash
cd src/api

# Build image
docker build -t yourproject-api:local .

# Run locally
docker run -p 8000:8000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  -e ENVIRONMENT="local" \
  yourproject-api:local

# Test
curl http://localhost:8000/health
```

**Step 4: Push to Azure Container Registry**

```bash
# Get ACR name from deployment outputs
ACR_NAME=$(cat outputs-dev.json | jq -r '.acrName.value')

# Login to ACR
az acr login --name $ACR_NAME

# Build and push using ACR Tasks (recommended - builds in Azure)
az acr build \
  --registry $ACR_NAME \
  --image yourproject-api:$(git rev-parse --short HEAD) \
  --image yourproject-api:latest \
  --file src/api/Dockerfile \
  src/api

# Or push locally built image
docker tag yourproject-api:local $ACR_NAME.azurecr.io/yourproject-api:latest
docker push $ACR_NAME.azurecr.io/yourproject-api:latest
```

**Step 5: Deploy to App Service**

```bash
# Configure App Service for container
az webapp config container set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --docker-custom-image-name $ACR_NAME.azurecr.io/yourproject-api:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io

# Enable continuous deployment from ACR
az webapp deployment container config \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --enable-cd true

# Restart app to pull new image
az webapp restart --name $APP_NAME --resource-group $RG_NAME

# Verify
az webapp show --name $APP_NAME --resource-group $RG_NAME --query "state" -o tsv
```

### Option C: GitHub Actions CI/CD (Production)

Best for: Automated deployments, team workflows

**Step 1: Create Service Principal**

```bash
# Create SP with minimal required permissions
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RG_NAME="rg-yourorg-yourproject-dev"

az ad sp create-for-rbac \
  --name "sp-yourproject-github" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME" \
  --sdk-auth > github-credentials.json

# Also grant ACR push permission
ACR_ID=$(az acr show --name $ACR_NAME --query id -o tsv)
SP_APP_ID=$(cat github-credentials.json | jq -r '.clientId')

az role assignment create \
  --assignee $SP_APP_ID \
  --role "AcrPush" \
  --scope $ACR_ID

echo "⚠️  Save github-credentials.json contents to GitHub Secrets, then delete the file!"
```

**Step 2: Configure GitHub Secrets**

Go to: Repository → Settings → Secrets and variables → Actions

Add these secrets:
| Secret Name | Value |
|-------------|-------|
| `AZURE_CREDENTIALS` | Contents of github-credentials.json |
| `AZURE_SUBSCRIPTION_ID` | Your subscription ID |
| `ACR_LOGIN_SERVER` | yourregistry.azurecr.io |
| `ACR_USERNAME` | From `az acr credential show` |
| `ACR_PASSWORD` | From `az acr credential show` |

**Step 3: Create Workflow Files**

`.github/workflows/ci.yml` (Continuous Integration):

```yaml
name: CI

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          pip install ruff black isort mypy
          pip install -r src/api/requirements.txt
      
      - name: Run Ruff
        run: ruff check src/api
      
      - name: Run Black
        run: black --check src/api
      
      - name: Run isort
        run: isort --check-only src/api
      
      - name: Run MyPy
        run: mypy src/api --ignore-missing-imports

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'
      
      - name: Install dependencies
        run: pip install -r src/api/requirements.txt -r src/api/requirements-dev.txt
      
      - name: Run tests
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test
        run: |
          cd src/api
          pytest tests/ -v --cov=. --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: src/api/coverage.xml

  build:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: |
          docker build -t yourproject-api:${{ github.sha }} src/api
          docker save yourproject-api:${{ github.sha }} > /tmp/image.tar
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: docker-image
          path: /tmp/image.tar
          retention-days: 1
```

`.github/workflows/deploy.yml` (Continuous Deployment):

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod

env:
  ENVIRONMENT: ${{ github.event.inputs.environment || 'dev' }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Login to ACR
        uses: azure/docker-login@v1
        with:
          login-server: ${{ secrets.ACR_LOGIN_SERVER }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}
      
      - name: Build and push image
        run: |
          IMAGE_TAG=${{ secrets.ACR_LOGIN_SERVER }}/yourproject-api:${{ github.sha }}
          docker build -t $IMAGE_TAG src/api
          docker push $IMAGE_TAG
          
          # Also tag as latest for this environment
          docker tag $IMAGE_TAG ${{ secrets.ACR_LOGIN_SERVER }}/yourproject-api:${{ env.ENVIRONMENT }}-latest
          docker push ${{ secrets.ACR_LOGIN_SERVER }}/yourproject-api:${{ env.ENVIRONMENT }}-latest
      
      - name: Deploy to App Service
        uses: azure/webapps-deploy@v2
        with:
          app-name: app-yourorg-yourproject-${{ env.ENVIRONMENT }}
          images: ${{ secrets.ACR_LOGIN_SERVER }}/yourproject-api:${{ github.sha }}
      
      - name: Health check
        run: |
          sleep 30
          curl -f https://app-yourorg-yourproject-${{ env.ENVIRONMENT }}.azurewebsites.net/health || exit 1
      
      - name: Notify on success
        if: success()
        run: echo "✅ Deployment to ${{ env.ENVIRONMENT }} successful!"
      
      - name: Notify on failure
        if: failure()
        run: echo "❌ Deployment to ${{ env.ENVIRONMENT }} failed!"

  notify-slack:
    runs-on: ubuntu-latest
    needs: deploy
    if: always()
    steps:
      - name: Send Slack notification
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          fields: repo,commit,author,action,eventName,workflow
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## Database Setup

### Initial Setup

```bash
# Get database connection details from outputs
DB_HOST=$(cat outputs-dev.json | jq -r '.databaseHost.value')
DB_NAME=$(cat outputs-dev.json | jq -r '.databaseName.value')
DB_USER="dbadmin"

# Set password (from Key Vault or secure storage)
read -sp "Database password: " DB_PASSWORD
echo

# Construct connection string
export DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME}?sslmode=require"
```

### Run Migrations

```bash
cd src/api

# Create initial migration (if not exists)
alembic revision --autogenerate -m "Initial migration"

# Run migrations
alembic upgrade head

# Check migration status
alembic current
alembic history
```

### Seed Data

```bash
# Run seed script
python scripts/seed_data.py

# Or run specific seeders
python -c "
from scripts.seeders import seed_users, seed_roles
seed_roles()
seed_users()
"
```

### Database Management Commands

```bash
# Connect to database
psql "$DATABASE_URL"

# Backup database
pg_dump "$DATABASE_URL" > backup-$(date +%Y%m%d).sql

# Restore database
psql "$DATABASE_URL" < backup-20240115.sql

# List tables
psql "$DATABASE_URL" -c "\dt"

# Check table sizes
psql "$DATABASE_URL" -c "
SELECT 
  relname as table,
  pg_size_pretty(pg_total_relation_size(relid)) as size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
"
```

### Automated Migration in CI/CD

Add to your deployment workflow:

```yaml
- name: Run database migrations
  run: |
    pip install alembic psycopg2-binary
    cd src/api
    alembic upgrade head
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

---

## Secrets Management

### Local Development

```bash
# Copy example file
cp .env.example .env

# Edit with your values
cat > .env << EOF
ENVIRONMENT=local
DEBUG=true

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/yourproject

# Auth
JWT_SECRET=local-dev-secret-change-in-production
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Azure (optional for local)
AZURE_STORAGE_CONNECTION_STRING=
APPLICATIONINSIGHTS_CONNECTION_STRING=
EOF
```

### Azure Key Vault Setup

```bash
# Get Key Vault name from outputs
KV_NAME=$(cat outputs-dev.json | jq -r '.keyVaultName.value')

# Add secrets
az keyvault secret set --vault-name $KV_NAME --name "DatabasePassword" --value "YourSecurePassword123!"
az keyvault secret set --vault-name $KV_NAME --name "JwtSecret" --value "$(openssl rand -hex 32)"

# List secrets
az keyvault secret list --vault-name $KV_NAME --output table
```

### Configure App Service with Key Vault References

```bash
# Enable managed identity
az webapp identity assign --name $APP_NAME --resource-group $RG_NAME

# Get identity principal ID
PRINCIPAL_ID=$(az webapp identity show --name $APP_NAME --resource-group $RG_NAME --query principalId -o tsv)

# Grant Key Vault access
az keyvault set-policy \
  --name $KV_NAME \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list

# Set app settings with Key Vault references
az webapp config appsettings set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --settings \
    DATABASE_PASSWORD="@Microsoft.KeyVault(VaultName=$KV_NAME;SecretName=DatabasePassword)" \
    JWT_SECRET="@Microsoft.KeyVault(VaultName=$KV_NAME;SecretName=JwtSecret)"
```

---

## Monitoring & Logging

### Application Insights Setup

```bash
# Get App Insights connection string
APPINSIGHTS_CONNECTION=$(az monitor app-insights component show \
  --app $APPINSIGHTS_NAME \
  --resource-group $RG_NAME \
  --query connectionString -o tsv)

# Configure App Service
az webapp config appsettings set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="$APPINSIGHTS_CONNECTION"
```

### View Logs

```bash
# Stream live logs
az webapp log tail --name $APP_NAME --resource-group $RG_NAME

# Query Application Insights
az monitor app-insights query \
  --app $APPINSIGHTS_NAME \
  --resource-group $RG_NAME \
  --analytics-query "requests | where timestamp > ago(1h) | summarize count() by resultCode"
```

### Set Up Alerts

```bash
# Create alert for high error rate
az monitor metrics alert create \
  --name "High Error Rate" \
  --resource-group $RG_NAME \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Web/sites/$APP_NAME" \
  --condition "avg Http5xx > 10" \
  --window-size 5m \
  --evaluation-frequency 1m
```

---

## Custom Domain & SSL

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name $APP_NAME \
  --resource-group $RG_NAME \
  --hostname api.yourdomain.com

# Enable SSL with managed certificate
az webapp config ssl create \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --hostname api.yourdomain.com

# Enforce HTTPS
az webapp update --name $APP_NAME --resource-group $RG_NAME --https-only true
```

---

## Environment Promotion

### Staging to Production (Blue-Green)

```bash
# Create staging slot
az webapp deployment slot create \
  --name $PROD_APP \
  --resource-group $PROD_RG \
  --slot staging

# Deploy to staging
az webapp config container set \
  --name $PROD_APP \
  --resource-group $PROD_RG \
  --slot staging \
  --docker-custom-image-name $ACR_NAME.azurecr.io/yourproject-api:$IMAGE_TAG

# Test staging
curl -f https://$PROD_APP-staging.azurewebsites.net/health

# Swap to production (zero-downtime)
az webapp deployment slot swap \
  --name $PROD_APP \
  --resource-group $PROD_RG \
  --slot staging \
  --target-slot production
```

---

## Rollback Procedures

### Immediate Rollback

```bash
# Swap back to previous version
az webapp deployment slot swap \
  --name $PROD_APP \
  --resource-group $PROD_RG \
  --slot staging \
  --target-slot production
```

### Rollback to Specific Version

```bash
# List recent images
az acr repository show-tags --name $ACR_NAME --repository yourproject-api --orderby time_desc --top 10

# Deploy specific version
az webapp config container set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --docker-custom-image-name $ACR_NAME.azurecr.io/yourproject-api:$ROLLBACK_TAG
```

---

## Disaster Recovery

### Backup Strategy

| Component | Method | Frequency | Retention |
|-----------|--------|-----------|-----------|
| Database | Azure Backup | Daily | 35 days |
| Key Vault | Soft delete | Automatic | 90 days |
| Storage | GRS Replication | Continuous | N/A |
| Container Images | ACR Geo-replication | Continuous | N/A |

### Database Point-in-Time Restore

```bash
az postgres flexible-server restore \
  --resource-group $RG_NAME \
  --name psql-yourproject-restored \
  --source-server psql-yourproject-prod \
  --restore-time "2024-01-15T10:00:00Z"
```

---

## Cost Optimization

### Resource Sizing by Environment

| Resource | Dev | Staging | Production |
|----------|-----|---------|------------|
| App Service | B1 | S1 | P1v3 |
| PostgreSQL | Burstable B1ms | GP D2s_v3 | GP D4s_v3 |
| Redis | Basic C0 | Standard C1 | Premium P1 |

### Auto-Shutdown Script

```bash
#!/bin/bash
# scripts/shutdown-dev.sh - Schedule via Azure Automation

az webapp stop --name app-yourorg-yourproject-dev --resource-group rg-yourorg-yourproject-dev
echo "Dev environment stopped for off-hours"
```

---

## Troubleshooting

### App Service Not Starting

```bash
az webapp log tail --name $APP_NAME --resource-group $RG_NAME
az webapp restart --name $APP_NAME --resource-group $RG_NAME
```

### Database Connection Failed

```bash
# Check firewall rules
az postgres flexible-server firewall-rule list --resource-group $RG_NAME --name $DB_SERVER_NAME

# Add your IP for debugging
az postgres flexible-server firewall-rule create \
  --resource-group $RG_NAME \
  --name $DB_SERVER_NAME \
  --rule-name "AllowMyIP" \
  --start-ip-address $(curl -s ifconfig.me) \
  --end-ip-address $(curl -s ifconfig.me)
```

### Key Vault Access Denied

```bash
# Check managed identity
az webapp identity show --name $APP_NAME --resource-group $RG_NAME

# Re-grant access
PRINCIPAL_ID=$(az webapp identity show --name $APP_NAME --resource-group $RG_NAME --query principalId -o tsv)
az keyvault set-policy --name $KV_NAME --object-id $PRINCIPAL_ID --secret-permissions get list
```

---

## Additional Resources

- [Azure App Service Docs](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure PostgreSQL Docs](https://docs.microsoft.com/en-us/azure/postgresql/)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [GitHub Actions for Azure](https://github.com/Azure/actions)

---

## Need Help?

- Check [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions
- Review [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines
- Open an issue in the repository
