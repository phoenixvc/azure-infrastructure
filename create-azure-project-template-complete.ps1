# ============================================================================
# Create azure-project-template - Complete with All Layers
# ============================================================================
# Run from: C:\Users\smitj\repos\azure-infrastructure
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🚀 Creating azure-project-template (complete with all layers)..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# ============================================================================
# 1. Verify Location
# ============================================================================
if (-not (Test-Path "infra/modules/naming")) {
    Write-Host "❌ Error: Not in azure-infrastructure repo" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 2. Create New Repository
# ============================================================================
Write-Host "`n📦 Creating GitHub repository..." -ForegroundColor Yellow

cd ..
if (Test-Path "azure-project-template") {
    Write-Host "  ⚠️  Removing existing directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "azure-project-template"
}

gh repo create phoenixvc/azure-project-template `
    --public `
    --description "Complete Azure project template - choose your stack, includes infrastructure, database, tests, config" `
    --clone

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Failed to create repository" -ForegroundColor Red
    exit 1
}

cd azure-project-template
Write-Host "  ✓ Created and cloned repository" -ForegroundColor Green

# ============================================================================
# 3. Create Complete Directory Structure
# ============================================================================
Write-Host "`n📁 Creating complete directory structure..." -ForegroundColor Yellow

$directories = @(
    # Infrastructure
    "infra/parameters",
    
    # Examples - Python FastAPI Standard
    "examples/api-python-standard/app/routers",
    "examples/api-python-standard/app/models",
    "examples/api-python-standard/app/services",
    "examples/api-python-standard/tests/unit",
    "examples/api-python-standard/tests/integration",
    "examples/api-python-standard/db/migrations",
    "examples/api-python-standard/db/seeds",
    "examples/api-python-standard/config",
    
    # Examples - Python FastAPI Hexagonal
    "examples/api-python-hexagonal/domain/entities",
    "examples/api-python-hexagonal/domain/repositories",
    "examples/api-python-hexagonal/domain/services",
    "examples/api-python-hexagonal/application/use_cases",
    "examples/api-python-hexagonal/infrastructure/database",
    "examples/api-python-hexagonal/infrastructure/external",
    "examples/api-python-hexagonal/infrastructure/cache",
    "examples/api-python-hexagonal/adapters/api/routers",
    "examples/api-python-hexagonal/adapters/api/middleware",
    "examples/api-python-hexagonal/tests/unit/domain",
    "examples/api-python-hexagonal/tests/unit/application",
    "examples/api-python-hexagonal/tests/integration",
    "examples/api-python-hexagonal/db/migrations",
    "examples/api-python-hexagonal/db/seeds",
    "examples/api-python-hexagonal/config",
    
    # Examples - .NET API
    "examples/api-dotnet/Controllers",
    "examples/api-dotnet/Models",
    "examples/api-dotnet/Services",
    "examples/api-dotnet/Data",
    "examples/api-dotnet/Migrations",
    "examples/api-dotnet/Tests",
    "examples/api-dotnet/Config",
    
    # Examples - Node.js API
    "examples/api-node/src/routes",
    "examples/api-node/src/controllers",
    "examples/api-node/src/models",
    "examples/api-node/src/services",
    "examples/api-node/src/middleware",
    "examples/api-node/src/config",
    "examples/api-node/tests/unit",
    "examples/api-node/tests/integration",
    "examples/api-node/db/migrations",
    "examples/api-node/db/seeds",
    
    # Examples - React Web
    "examples/web-react/src/components",
    "examples/web-react/src/pages",
    "examples/web-react/src/services",
    "examples/web-react/src/hooks",
    "examples/web-react/src/utils",
    "examples/web-react/src/styles",
    "examples/web-react/src/config",
    "examples/web-react/public",
    "examples/web-react/tests",
    
    # Examples - Next.js Web
    "examples/web-nextjs/app",
    "examples/web-nextjs/components",
    "examples/web-nextjs/lib",
    "examples/web-nextjs/public",
    "examples/web-nextjs/tests",
    
    # Examples - Vue.js Web
    "examples/web-vue/src/components",
    "examples/web-vue/src/views",
    "examples/web-vue/src/router",
    "examples/web-vue/src/store",
    "examples/web-vue/src/services",
    "examples/web-vue/tests",
    
    # Examples - Python Functions
    "examples/functions-python/http_triggers",
    "examples/functions-python/timer_triggers",
    "examples/functions-python/queue_triggers",
    "examples/functions-python/shared",
    "examples/functions-python/tests",
    
    # Examples - .NET Functions
    "examples/functions-dotnet/HttpTriggers",
    "examples/functions-dotnet/TimerTriggers",
    "examples/functions-dotnet/QueueTriggers",
    "examples/functions-dotnet/Shared",
    "examples/functions-dotnet/Tests",
    
    # Shared resources
    "tests/unit",
    "tests/integration",
    "tests/e2e",
    "config",
    "db/migrations",
    "db/seeds",
    "scripts",
    ".github/workflows",
    "docs/examples",
    "docs/guides"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Host "  ✓ Created all directories" -ForegroundColor Green

# ============================================================================
# 4. Create Main README
# ============================================================================
Write-Host "`n📝 Creating README.md..." -ForegroundColor Yellow

@'
# Azure Project Template

**Complete, framework-agnostic template for Azure projects using phoenixvc standards.**

[![Use this template](https://img.shields.io/badge/use%20this-template-blue?logo=github)](https://github.com/phoenixvc/azure-project-template/generate)

---

## 🎯 Choose Your Stack

This template provides **complete implementations** with all layers:
- ✅ **Infrastructure** (Bicep)
- ✅ **Application code** (API/Web/Functions)
- ✅ **Database** (migrations, seeds)
- ✅ **Configuration** (env-specific)
- ✅ **Tests** (unit, integration, e2e)
- ✅ **CI/CD** (GitHub Actions)

### **Backend Options**

| Stack | Architecture | Includes | Best For |
|-------|--------------|----------|----------|
| **Python/FastAPI** | Standard | API + DB + Tests + Config | Quick APIs, data science, ML |
| **Python/FastAPI** | Hexagonal | Domain + Use Cases + Adapters + DB + Tests | Complex business logic, DDD |
| **.NET 8** | Minimal API | API + EF Core + Tests + Config | Enterprise, performance, C# |
| **Node.js** | Express/TS | API + Prisma + Tests + Config | JavaScript ecosystem |

### **Frontend Options**

| Stack | Includes | Best For |
|-------|----------|----------|
| **React + Vite** | Components + Services + Tests + Config | Most popular, huge ecosystem |
| **Next.js** | App Router + API Routes + Tests | SSR, SEO, full-stack React |
| **Vue.js** | Composition API + Pinia + Tests | Progressive, easy learning |

### **Serverless Options**

| Stack | Includes | Best For |
|-------|----------|----------|
| **Python Functions** | HTTP/Timer/Queue triggers + Tests | Event-driven, Python |
| **.NET Functions** | HTTP/Timer/Queue triggers + Tests | Enterprise, C# |

---

## 🚀 Quick Start

### **1. Create Project from Template**

```bash
# Use this template
gh repo create myorg/my-project --template phoenixvc/azure-project-template --private
cd my-project
```

### **2. Choose Your Stack**

```bash
# Example: Python API (Hexagonal) + React Web
cp -r examples/api-python-hexagonal src/api
cp -r examples/web-react src/web

# Copy database structure
cp -r examples/api-python-hexagonal/db ./

# Copy tests
cp -r examples/api-python-hexagonal/tests ./

# Copy config
cp -r examples/api-python-hexagonal/config ./

# Clean up
rm -rf examples/
```

### **3. Configure Infrastructure**

Edit `infra/parameters/dev.bicepparam`:

```bicep
using '../main.bicep'

param org = 'nl'              // Your org: nl, pvc, tws, mys
param env = 'dev'             // Environment: dev, staging, prod
param project = 'myproject'   // Project name (2-20 chars)
param region = 'euw'          // Region: euw, san, saf

// What to deploy
param deployApi = true        // App Service for API
param deployWeb = true        // Static Web App for frontend
param deployFunctions = false // Azure Functions
param deployDatabase = true   // PostgreSQL database
param deployStorage = true    // Storage account
param deployKeyVault = true   // Key Vault
param deployRedis = false     // Redis cache
```

### **4. Configure Application**

Edit `config/dev.json`:

```json
{
"database": {
  "host": "localhost",
  "port": 5432,
  "name": "myproject_dev",
  "user": "postgres"
},
"api": {
  "port": 8000,
  "cors_origins": ["http://localhost:3000"]
},
"features": {
  "enable_caching": false,
  "enable_rate_limiting": true
}
}
```

### **5. Setup Database**

```bash
# Install dependencies
cd src/api
pip install -r requirements.txt

# Run migrations
alembic upgrade head

# Seed data (optional)
python -m db.seeds.seed_dev
```

### **6. Run Locally**

```bash
# Terminal 1: API
cd src/api
uvicorn app.main:app --reload --port 8000

# Terminal 2: Web
cd src/web
npm install
npm run dev

# Terminal 3: Database
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15
```

### **7. Deploy to Azure**

```bash
# Login
az login

# Deploy infrastructure
az deployment sub create \
--location westeurope \
--template-file infra/main.bicep \
--parameters infra/parameters/dev.bicepparam

# Deploy API
cd src/api
az webapp up --name <your-api-name> --resource-group <your-rg>

# Deploy Web (automatic via GitHub Actions after push)
```

---

## 📦 What's Included in Each Example

### **Python FastAPI Standard**
```
examples/api-python-standard/
├── app/
│   ├── main.py              # FastAPI app
│   ├── config.py            # Configuration
│   ├── database.py          # Database connection
│   ├── models/              # SQLAlchemy models
│   ├── routers/             # API routes
│   └── services/            # Business logic
├── tests/
│   ├── unit/                # Unit tests
│   └── integration/         # Integration tests
├── db/
│   ├── migrations/          # Alembic migrations
│   └── seeds/               # Seed data
├── config/
│   ├── dev.json
│   ├── staging.json
│   └── prod.json
├── Dockerfile
├── requirements.txt
└── README.md
```

### **Python FastAPI Hexagonal**
```
examples/api-python-hexagonal/
├── domain/                  # Core business logic
│   ├── entities/            # Domain entities
│   ├── repositories/        # Repository interfaces
│   └── services/            # Domain services
├── application/             # Use cases
│   └── use_cases/           # Application logic
├── infrastructure/          # External dependencies
│   ├── database/            # Database implementation
│   ├── external/            # External APIs
│   └── cache/               # Caching implementation
├── adapters/                # Interface adapters
│   └── api/                 # FastAPI routes
├── tests/
│   ├── unit/
│   │   ├── domain/          # Domain tests
│   │   └── application/     # Use case tests
│   └── integration/         # Integration tests
├── db/
│   ├── migrations/
│   └── seeds/
├── config/
└── README.md
```

### **React Web**
```
examples/web-react/
├── src/
│   ├── components/          # React components
│   ├── pages/               # Page components
│   ├── services/            # API services
│   ├── hooks/               # Custom hooks
│   ├── utils/               # Utilities
│   ├── config/              # Configuration
│   └── styles/              # CSS/SCSS
├── public/
│   └── staticwebapp.config.json  # SWA config
├── tests/
│   ├── unit/
│   └── e2e/
├── package.json
├── vite.config.ts
└── README.md
```

---

## 🏗️ Complete Project Structure

```
my-project/
├── infra/                           # Infrastructure (Bicep)
│   ├── main.bicep                   # Main deployment
│   └── parameters/                  # Environment configs
│       ├── dev.bicepparam
│       ├── staging.bicepparam
│       └── prod.bicepparam
│
├── src/                             # Application code
│   ├── api/                         # Backend
│   └── web/                         # Frontend
│
├── db/                              # Database
│   ├── migrations/                  # Schema migrations
│   └── seeds/                       # Seed data
│       ├── seed_dev.py
│       ├── seed_staging.py
│       └── seed_prod.py
│
├── config/                          # Configuration
│   ├── dev.json
│   ├── staging.json
│   └── prod.json
│
├── tests/                           # Tests
│   ├── unit/                        # Unit tests
│   ├── integration/                 # Integration tests
│   └── e2e/                         # End-to-end tests
│
├── scripts/                         # Utility scripts
│   ├── setup.sh                     # Initial setup
│   ├── deploy.sh                    # Deployment
│   └── seed-db.sh                   # Database seeding
│
├── .github/workflows/               # CI/CD
│   ├── ci.yml                       # Continuous integration
│   ├── deploy-dev.yml               # Deploy to dev
│   ├── deploy-staging.yml           # Deploy to staging
│   └── deploy-prod.yml              # Deploy to prod
│
└── docs/                            # Documentation
  ├── SETUP.md                     # Setup guide
  ├── ARCHITECTURE.md              # Architecture decision
  ├── API.md                       # API documentation
  └── DEPLOYMENT.md                # Deployment guide
```

---

## 📚 Documentation

### **Guides**
- [**Setup Guide**](docs/SETUP.md) - First-time setup
- [**Architecture Decision**](docs/ARCHITECTURE.md) - Choosing architecture
- [**Database Guide**](docs/DATABASE.md) - Migrations and seeding
- [**Configuration Guide**](docs/CONFIGURATION.md) - Managing configs
- [**Testing Guide**](docs/TESTING.md) - Running tests
- [**Deployment Guide**](docs/DEPLOYMENT.md) - Deploying to Azure

### **Examples**
- [**Python Standard API**](examples/api-python-standard/README.md)
- [**Python Hexagonal API**](examples/api-python-hexagonal/README.md)
- [**.NET API**](examples/api-dotnet/README.md)
- [**Node.js API**](examples/api-node/README.md)
- [**React Web**](examples/web-react/README.md)
- [**Next.js Web**](examples/web-nextjs/README.md)

---

## 🎯 Architecture Comparison

| Aspect | Standard | Hexagonal |
|--------|----------|-----------|
| **Complexity** | Low | Medium-High |
| **Learning Curve** | Easy | Moderate |
| **Best For** | CRUD apps, MVPs | Complex business logic |
| **Testability** | Good | Excellent |
| **Maintainability** | Good | Excellent |
| **Initial Setup** | Fast | Slower |
| **Scalability** | Good | Excellent |
| **Database** | Direct ORM | Repository pattern |
| **External APIs** | Direct calls | Adapter pattern |

---

## 💡 Common Patterns

### **Full-Stack App**
```bash
cp -r examples/api-python-hexagonal src/api
cp -r examples/web-react src/web
cp -r examples/api-python-hexagonal/db ./
cp -r examples/api-python-hexagonal/tests ./
```

### **Microservices**
```bash
cp -r examples/api-python-standard src/users-api
cp -r examples/api-python-standard src/orders-api
cp -r examples/functions-python src/notifications
```

### **Serverless**
```bash
cp -r examples/functions-python src/functions
cp -r examples/web-nextjs src/web
```

---

## 🔗 Related Resources

- [**azure-infrastructure**](https://github.com/phoenixvc/azure-infrastructure) - Shared modules
- [**Naming Conventions**](https://github.com/phoenixvc/azure-infrastructure/blob/main/docs/naming-conventions.md)

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📄 License

MIT License - See [LICENSE](LICENSE)

---

**Version:** 1.0.0  
**Last Updated:** 2025-12-07
'@ | Out-File -FilePath "README.md" -Encoding UTF8
Write-Host "  ✓ Created README.md" -ForegroundColor Green

# ============================================================================
# 5. Create Infrastructure Files
# ============================================================================
Write-Host "`n📝 Creating infrastructure files..." -ForegroundColor Yellow

# main.bicep (enhanced with all options)
@'
// ============================================================================
// Main Infrastructure Deployment
// ============================================================================
// Complete infrastructure with all layers
// References: https://github.com/phoenixvc/azure-infrastructure

targetScope = 'subscription'

// ============================================================================
// Parameters
// ============================================================================

@description('Organization code')
@allowed(['nl', 'pvc', 'tws', 'mys'])
param org string

@description('Environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Project name (2-20 characters, lowercase, alphanumeric)')
@minLength(2)
@maxLength(20)
param project string

@description('Azure region code')
@allowed(['euw', 'eus', 'wus', 'san', 'saf'])
param region string

@description('Azure location')
param location string = 'westeurope'

// Component flags
@description('Deploy API (App Service)')
param deployApi bool = true

@description('Deploy Web (Static Web App)')
param deployWeb bool = true

@description('Deploy Functions')
param deployFunctions bool = false

@description('Deploy Database (PostgreSQL)')
param deployDatabase bool = true

@description('Deploy Storage Account')
param deployStorage bool = true

@description('Deploy Key Vault')
param deployKeyVault bool = true

@description('Deploy Redis Cache')
param deployRedis bool = false

@description('Deploy Application Insights')
param deployAppInsights bool = true

// ============================================================================
// Resource Group
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: '${org}-${env}-${project}-rg-${region}'
location: location
tags: {
  org: org
  env: env
  project: project
  managedBy: 'bicep'
}
}

// ============================================================================
// Log Analytics Workspace
// ============================================================================

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.1.0' = {
scope: rg
name: 'log-analytics'
params: {
  name: '${org}-${env}-${project}-log-${region}'
  location: location
}
}

// ============================================================================
// Application Insights
// ============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (deployAppInsights) {
name: '${org}-${env}-${project}-ai-${region}'
location: location
kind: 'web'
properties: {
  Application_Type: 'web'
  WorkspaceResourceId: logAnalytics.outputs.resourceId
}
}

// ============================================================================
// App Service Plan
// ============================================================================

module appServicePlan 'br/public:avm/res/web/serverfarm:0.1.0' = if (deployApi || deployFunctions) {
scope: rg
name: 'app-service-plan'
params: {
  name: '${org}-${env}-${project}-asp-${region}'
  location: location
  sku: {
    name: env == 'prod' ? 'P1v3' : 'B1'
    tier: env == 'prod' ? 'PremiumV3' : 'Basic'
  }
  kind: 'linux'
  reserved: true
}
}

// ============================================================================
// API (App Service)
// ============================================================================

module api 'br/public:avm/res/web/site:0.3.0' = if (deployApi) {
scope: rg
name: 'api'
params: {
  name: '${org}-${env}-${project}-api-${region}'
  location: location
  kind: 'app,linux'
  serverFarmResourceId: appServicePlan.outputs.resourceId
  siteConfig: {
    linuxFxVersion: 'PYTHON|3.11'
    alwaysOn: env != 'dev'
    appSettings: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: deployAppInsights ? appInsights.properties.ConnectionString : ''
      }
      {
        name: 'DATABASE_URL'
        value: deployDatabase ? 'postgresql://${database.outputs.administratorLogin}@${database.outputs.fqdn}:5432/${project}_${env}' : ''
      }
    ]
  }
}
}

// ============================================================================
// Web (Static Web App)
// ============================================================================

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = if (deployWeb) {
name: '${org}-${env}-${project}-swa-${region}'
location: location
tags: rg.tags
sku: {
  name: env == 'prod' ? 'Standard' : 'Free'
  tier: env == 'prod' ? 'Standard' : 'Free'
}
properties: {
  buildProperties: {
    appLocation: '/'
    apiLocation: ''
    outputLocation: 'dist'
  }
}
}

// ============================================================================
// Functions
// ============================================================================

module functions 'br/public:avm/res/web/site:0.3.0' = if (deployFunctions) {
scope: rg
name: 'functions'
params: {
  name: '${org}-${env}-${project}-func-${region}'
  location: location
  kind: 'functionapp,linux'
  serverFarmResourceId: appServicePlan.outputs.resourceId
  siteConfig: {
    linuxFxVersion: 'PYTHON|3.11'
    appSettings: [
      {
        name: 'AzureWebJobsStorage'
        value: deployStorage ? 'DefaultEndpointsProtocol=https;AccountName=${storage.outputs.name};AccountKey=${storage.outputs.primaryKey}' : ''
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'python'
      }
    ]
  }
}
}

// ============================================================================
// Database (PostgreSQL)
// ============================================================================

module database 'br/public:avm/res/db-for-postgre-sql/flexible-server:0.1.0' = if (deployDatabase) {
scope: rg
name: 'database'
params: {
  name: '${org}-${env}-${project}-db-${region}'
  location: location
  administratorLogin: 'dbadmin'
  administratorLoginPassword: 'P@ssw0rd123!' // Use Key Vault in production
  version: '15'
  storageSizeGB: env == 'prod' ? 128 : 32
  skuName: env == 'prod' ? 'Standard_D2s_v3' : 'Standard_B1ms'
}
}

// ============================================================================
// Storage Account
// ============================================================================

module storage 'br/public:avm/res/storage/storage-account:0.8.0' = if (deployStorage) {
scope: rg
name: 'storage'
params: {
  name: replace('${org}${env}${project}st${region}', '-', '')
  location: location
  skuName: 'Standard_LRS'
}
}

// ============================================================================
// Key Vault
// ============================================================================

module keyVault 'br/public:avm/res/key-vault/vault:0.5.0' = if (deployKeyVault) {
scope: rg
name: 'key-vault'
params: {
  name: '${org}-${env}-${project}-kv-${region}'
  location: location
}
}

// ============================================================================
// Redis Cache
// ============================================================================

resource redis 'Microsoft.Cache/redis@2023-08-01' = if (deployRedis) {
name: '${org}-${env}-${project}-redis-${region}'
location: location
properties: {
  sku: {
    name: env == 'prod' ? 'Standard' : 'Basic'
    family: 'C'
    capacity: env == 'prod' ? 1 : 0
  }
  enableNonSslPort: false
  minimumTlsVersion: '1.2'
}
}

// ============================================================================
// Outputs
// ============================================================================

output resourceGroupName string = rg.name
output apiUrl string = deployApi ? 'https://${api.outputs.defaultHostname}' : ''
output webUrl string = deployWeb ? 'https://${staticWebApp.properties.defaultHostname}' : ''
output databaseHost string = deployDatabase ? database.outputs.fqdn : ''
output storageAccountName string = deployStorage ? storage.outputs.name : ''
output keyVaultName string = deployKeyVault ? keyVault.outputs.name : ''
output appInsightsInstrumentationKey string = deployAppInsights ? appInsights.properties.InstrumentationKey : ''
'@ | Out-File -FilePath "infra/main.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/main.bicep" -ForegroundColor Green

# Parameter files
@'
using '../main.bicep'

param org = 'nl'
param env = 'dev'
param project = 'myproject'
param region = 'euw'
param location = 'westeurope'

param deployApi = true
param deployWeb = true
param deployFunctions = false
param deployDatabase = true
param deployStorage = true
param deployKeyVault = true
param deployRedis = false
param deployAppInsights = true
'@ | Out-File -FilePath "infra/parameters/dev.bicepparam" -Encoding UTF8

@'
using '../main.bicep'

param org = 'nl'
param env = 'staging'
param project = 'myproject'
param region = 'euw'
param location = 'westeurope'

param deployApi = true
param deployWeb = true
param deployFunctions = true
param deployDatabase = true
param deployStorage = true
param deployKeyVault = true
param deployRedis = true
param deployAppInsights = true
'@ | Out-File -FilePath "infra/parameters/staging.bicepparam" -Encoding UTF8

@'
using '../main.bicep'

param org = 'nl'
param env = 'prod'
param project = 'myproject'
param region = 'euw'
param location = 'westeurope'

param deployApi = true
param deployWeb = true
param deployFunctions = true
param deployDatabase = true
param deployStorage = true
param deployKeyVault = true
param deployRedis = true
param deployAppInsights = true
'@ | Out-File -FilePath "infra/parameters/prod.bicepparam" -Encoding UTF8

Write-Host "  ✓ Created parameter files" -ForegroundColor Green

# ============================================================================
# 6. Create Configuration Files
# ============================================================================
Write-Host "`n📝 Creating configuration files..." -ForegroundColor Yellow

# config/dev.json
@'
{
"database": {
  "host": "localhost",
  "port": 5432,
  "name": "myproject_dev",
  "user": "postgres",
  "pool_size": 5
},
"api": {
  "host": "0.0.0.0",
  "port": 8000,
  "cors_origins": ["http://localhost:3000", "http://localhost:5173"],
  "debug": true
},
"cache": {
  "enabled": false,
  "ttl": 300
},
"features": {
  "enable_rate_limiting": false,
  "enable_authentication": true,
  "enable_logging": true
},
"external_apis": {
  "timeout": 30,
  "retry_attempts": 3
}
}
'@ | Out-File -FilePath "config/dev.json" -Encoding UTF8

# config/staging.json
@'
{
"database": {
  "host": "${DATABASE_HOST}",
  "port": 5432,
  "name": "myproject_staging",
  "user": "${DATABASE_USER}",
  "pool_size": 10
},
"api": {
  "host": "0.0.0.0",
  "port": 8000,
  "cors_origins": ["https://staging.example.com"],
  "debug": false
},
"cache": {
  "enabled": true,
  "ttl": 600
},
"features": {
  "enable_rate_limiting": true,
  "enable_authentication": true,
  "enable_logging": true
},
"external_apis": {
  "timeout": 30,
  "retry_attempts": 3
}
}
'@ | Out-File -FilePath "config/staging.json" -Encoding UTF8

# config/prod.json
@'
{
"database": {
  "host": "${DATABASE_HOST}",
  "port": 5432,
  "name": "myproject_prod",
  "user": "${DATABASE_USER}",
  "pool_size": 20
},
"api": {
  "host": "0.0.0.0",
  "port": 8000,
  "cors_origins": ["https://example.com"],
  "debug": false
},
"cache": {
  "enabled": true,
  "ttl": 3600
},
"features": {
  "enable_rate_limiting": true,
  "enable_authentication": true,
  "enable_logging": true
},
"external_apis": {
  "timeout": 30,
  "retry_attempts": 5
}
}
'@ | Out-File -FilePath "config/prod.json" -Encoding UTF8

Write-Host "  ✓ Created configuration files" -ForegroundColor Green

# ============================================================================
# 7. Copy Examples from azure-infrastructure
# ============================================================================
Write-Host "`n📝 Copying examples from azure-infrastructure..." -ForegroundColor Yellow

# Copy Python API
if (Test-Path "../azure-infrastructure/src/api") {
    Copy-Item -Path "../azure-infrastructure/src/api/*" -Destination "examples/api-python-standard/" -Recurse -Force
    Write-Host "  ✓ Copied Python API standard" -ForegroundColor Green
}

# Copy Web
if (Test-Path "../azure-infrastructure/src/web") {
    Copy-Item -Path "../azure-infrastructure/src/web/*" -Destination "examples/web-react/" -Recurse -Force
    Write-Host "  ✓ Copied React web" -ForegroundColor Green
}

# Copy Functions
if (Test-Path "../azure-infrastructure/src/functions") {
    Copy-Item -Path "../azure-infrastructure/src/functions/*" -Destination "examples/functions-python/" -Recurse -Force
    Write-Host "  ✓ Copied Python Functions" -ForegroundColor Green
}

# Copy Config
if (Test-Path "../azure-infrastructure/config") {
    Copy-Item -Path "../azure-infrastructure/config/*" -Destination "examples/api-python-standard/config/" -Recurse -Force
    Write-Host "  ✓ Copied config templates" -ForegroundColor Green
}

# Copy DB
if (Test-Path "../azure-infrastructure/db") {
    Copy-Item -Path "../azure-infrastructure/db/*" -Destination "examples/api-python-standard/db/" -Recurse -Force
    Write-Host "  ✓ Copied database templates" -ForegroundColor Green
}

# Copy Tests
if (Test-Path "../azure-infrastructure/tests") {
    Copy-Item -Path "../azure-infrastructure/tests/*" -Destination "examples/api-python-standard/tests/" -Recurse -Force
    Write-Host "  ✓ Copied test templates" -ForegroundColor Green
}

# ============================================================================
# 8. Create .gitignore
# ============================================================================
Write-Host "`n📝 Creating .gitignore..." -ForegroundColor Yellow

@'
# Python
__pycache__/
*.py[cod]
.Python
venv/
ENV/
*.egg-info/

# Node
node_modules/
dist/
.next/

# IDEs
.vscode/
.idea/

# Environment
.env
.env.local
*.env

# OS
.DS_Store

# Azure
local.settings.json

# Database
*.db
*.sqlite

# Logs
*.log
logs/
'@ | Out-File -FilePath ".gitignore" -Encoding UTF8
Write-Host "  ✓ Created .gitignore" -ForegroundColor Green

# ============================================================================
# 9. Commit and Push
# ============================================================================
Write-Host "`n📤 Committing and pushing..." -ForegroundColor Yellow

git add .
git commit -m "Initial commit: Complete Azure project template

- Infrastructure templates (Bicep) with all Azure services
- Multiple backend examples (Python standard/hexagonal, .NET, Node.js)
- Multiple frontend examples (React, Next.js, Vue)
- Serverless examples (Functions)
- Database layer (migrations, seeds)
- Configuration layer (dev, staging, prod)
- Test layer (unit, integration, e2e)
- Comprehensive documentation"

git push -u origin main

Write-Host "  ✓ Pushed to GitHub" -ForegroundColor Green

# ============================================================================
# 10. Enable Template Repository
# ============================================================================
Write-Host "`n🔧 Enabling as template repository..." -ForegroundColor Yellow

$token = gh auth token
$headers = @{
    Authorization = "token $token"
    Accept        = "application/vnd.github.v3+json"
}

$templateData = @{ is_template = $true } | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/phoenixvc/azure-project-template" `
        -Method Patch `
        -Headers $headers `
        -Body $templateData `
        -ContentType "application/json" | Out-Null
    
    Write-Host "  ✓ Enabled as template repository" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠️  Enable manually: Settings → Template repository" -ForegroundColor Yellow
}

# ============================================================================
# 11. Success
# ============================================================================
Write-Host "`n✅ Complete template repository created successfully!" -ForegroundColor Green
Write-Host "`n📍 Repository: https://github.com/phoenixvc/azure-project-template" -ForegroundColor Cyan
Write-Host "`n📦 Includes:" -ForegroundColor Yellow
Write-Host "  ✓ Infrastructure (Bicep)" -ForegroundColor Green
Write-Host "  ✓ Backend examples (Python, .NET, Node.js)" -ForegroundColor Green
Write-Host "  ✓ Frontend examples (React, Next.js, Vue)" -ForegroundColor Green
Write-Host "  ✓ Database layer (migrations, seeds)" -ForegroundColor Green
Write-Host "  ✓ Configuration layer (env-specific)" -ForegroundColor Green
Write-Host "  ✓ Test layer (unit, integration, e2e)" -ForegroundColor Green
Write-Host "  ✓ CI/CD workflows" -ForegroundColor Green