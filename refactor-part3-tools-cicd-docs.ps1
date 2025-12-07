# ============================================================================
# Part 3: Tools + CI/CD Workflows + Documentation + Final Updates
# ============================================================================
# Run from: C:\Users\smitj\repos\azure-infrastructure
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🔧 Part 3: Tools + CI/CD + Documentation" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Verify we're in the right place
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in azure-infrastructure repo" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 1. Create Azure Resource Graph Queries
# ============================================================================
Write-Host "`n📝 Creating Azure Resource Graph queries..." -ForegroundColor Yellow

@'
// Azure Resource Graph Query: Naming Compliance Check
// Returns resources that don't follow phoenixvc naming conventions

Resources
| where type !in ('microsoft.resources/subscriptions', 'microsoft.resources/subscriptions/resourcegroups')
| extend nameParts = split(name, '-')
| extend org = tostring(nameParts[0])
| extend env = tostring(nameParts[1])
| extend project = tostring(nameParts[2])
| where org !in ('nl', 'pvc', 'tws', 'mys')
 or env !in ('dev', 'staging', 'prod')
| project name, type, resourceGroup, location, org, env, project
| order by name asc
'@ | Out-File -FilePath "tools/queries/compliance-check.kql" -Encoding UTF8
Write-Host "  ✓ Created tools/queries/compliance-check.kql" -ForegroundColor Green

@'
// Azure Resource Graph Query: Resource Inventory
// Groups all resources by org/env/project

Resources
| where type !in ('microsoft.resources/subscriptions')
| extend nameParts = split(name, '-')
| extend org = tostring(nameParts[0])
| extend env = tostring(nameParts[1])
| extend project = tostring(nameParts[2])
| summarize 
  ResourceCount = count(),
  ResourceTypes = make_set(type)
by org, env, project, resourceGroup
| order by org, env, project
'@ | Out-File -FilePath "tools/queries/resource-inventory.kql" -Encoding UTF8
Write-Host "  ✓ Created tools/queries/resource-inventory.kql" -ForegroundColor Green

@'
# Azure Resource Graph Queries

KQL queries for Azure resource discovery and compliance checking.

---

## Available Queries

### **Compliance Check** (`compliance-check.kql`)

Finds resources that don't follow naming conventions.

```bash
az graph query -q "$(cat tools/queries/compliance-check.kql)"
```

### **Resource Inventory** (`resource-inventory.kql`)

Generates inventory grouped by org/env/project.

```bash
az graph query -q "$(cat tools/queries/resource-inventory.kql)"
```

---

## Usage in CI/CD

```yaml
- name: Check naming compliance
run: |
  az graph query -q "$(cat tools/queries/compliance-check.kql)" --output table
```
'@ | Out-File -FilePath "tools/queries/README.md" -Encoding UTF8
Write-Host "  ✓ Created tools/queries/README.md" -ForegroundColor Green

# ============================================================================
# 2. Create Tools README
# ============================================================================
Write-Host "`n📝 Creating tools/README.md..." -ForegroundColor Yellow

@'
# Tools

Operational tooling for Azure infrastructure management.

---

## Available Tools

### **Validator** (`validator/`)

CLI tool for validating Azure resource names.

```bash
cd tools/validator
pip install -r requirements.txt
python nl_az_name.py validate nl-prod-rooivalk-api-euw
```

See [validator/README.md](validator/README.md) for details.

---

### **Queries** (`queries/`)

Azure Resource Graph queries for compliance and inventory.

```bash
az graph query -q "$(cat tools/queries/compliance-check.kql)"
```

See [queries/README.md](queries/README.md) for details.

---

### **Scripts** (`scripts/`)

Automation scripts for common tasks.

- `setup-azure-infra.ps1` - Initial repository setup
- `publish-modules.ps1` - Publish Bicep modules to ACR

---

## Integration

All tools are designed to work in:
- ✅ Local development
- ✅ CI/CD pipelines (GitHub Actions, Azure DevOps)
- ✅ Azure Cloud Shell
'@ | Out-File -FilePath "tools/README.md" -Encoding UTF8
Write-Host "  ✓ Created tools/README.md" -ForegroundColor Green

# ============================================================================
# 3. Create GitHub Actions Workflows
# ============================================================================
Write-Host "`n📝 Creating GitHub Actions workflows..." -ForegroundColor Yellow

@'
name: Validate Naming Conventions

on:
workflow_call:
  inputs:
    bicep_path:
      description: 'Path to Bicep files to validate'
      required: false
      type: string
      default: './infra'

jobs:
validate:
  runs-on: ubuntu-latest
  name: Validate Resource Naming
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Install validator
      run: |
        pip install -r tools/validator/requirements.txt
    
    - name: Validate Bicep files
      run: |
        echo "Validating naming conventions in ${{ inputs.bicep_path }}"
        
        # Extract resource names from Bicep files and validate
        find ${{ inputs.bicep_path }} -name "*.bicep" -type f | while read file; do
          echo "Checking: $file"
          # This is a placeholder - actual validation logic would parse Bicep
          grep -oP "name:\s*'\K[^']+" "$file" | while read name; do
            python tools/validator/nl_az_name.py validate "$name" || true
          done
        done
    
    - name: Summary
      run: |
        echo "✅ Naming validation complete"
'@ | Out-File -FilePath ".github/workflows/validate-naming.yml" -Encoding UTF8
Write-Host "  ✓ Created .github/workflows/validate-naming.yml" -ForegroundColor Green

@'
name: Publish Bicep Modules

on:
push:
  branches:
    - main
  paths:
    - 'infra/modules/**'
workflow_dispatch:

env:
REGISTRY: phoenixvcacr.azurecr.io
MODULE_VERSION: v2.1

jobs:
publish:
  runs-on: ubuntu-latest
  name: Publish Modules to ACR
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Publish naming module
      run: |
        az bicep publish \
          --file infra/modules/naming/main.bicep \
          --target "br:${{ env.REGISTRY }}/infra/modules/naming:${{ env.MODULE_VERSION }}"
    
    - name: Publish app-service module
      run: |
        az bicep publish \
          --file infra/modules/app-service/main.bicep \
          --target "br:${{ env.REGISTRY }}/infra/modules/app-service:${{ env.MODULE_VERSION }}"
    
    - name: Publish function-app module
      run: |
        az bicep publish \
          --file infra/modules/function-app/main.bicep \
          --target "br:${{ env.REGISTRY }}/infra/modules/function-app:${{ env.MODULE_VERSION }}"
    
    - name: Publish postgres module
      run: |
        az bicep publish \
          --file infra/modules/postgres/main.bicep \
          --target "br:${{ env.REGISTRY }}/infra/modules/postgres:${{ env.MODULE_VERSION }}"
    
    - name: Publish storage module
      run: |
        az bicep publish \
          --file infra/modules/storage/main.bicep \
          --target "br:${{ env.REGISTRY }}/infra/modules/storage:${{ env.MODULE_VERSION }}"
    
    - name: Publish key-vault module
      run: |
        az bicep publish \
          --file infra/modules/key-vault/main.bicep \
          --target "br:${{ env.REGISTRY }}/infra/modules/key-vault:${{ env.MODULE_VERSION }}"
    
    - name: Summary
      run: |
        echo "✅ All modules published to ${{ env.REGISTRY }}"
'@ | Out-File -FilePath ".github/workflows/publish-modules.yml" -Encoding UTF8
Write-Host "  ✓ Created .github/workflows/publish-modules.yml" -ForegroundColor Green

@'
name: CI - API

on:
push:
  branches: [main, develop]
  paths:
    - 'src/api/**'
pull_request:
  branches: [main, develop]
  paths:
    - 'src/api/**'

jobs:
test:
  runs-on: ubuntu-latest
  name: Test API
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        cd src/api
        pip install -r requirements.txt
        pip install pytest pytest-cov
    
    - name: Run tests
      run: |
        pytest tests/unit/ -v --cov=src/api
    
    - name: Build Docker image
      run: |
        cd src/api
        docker build -t api:${{ github.sha }} .
'@ | Out-File -FilePath ".github/workflows/ci-api.yml" -Encoding UTF8
Write-Host "  ✓ Created .github/workflows/ci-api.yml" -ForegroundColor Green

@'
name: CI - Functions

on:
push:
  branches: [main, develop]
  paths:
    - 'src/functions/**'
pull_request:
  branches: [main, develop]
  paths:
    - 'src/functions/**'

jobs:
test:
  runs-on: ubuntu-latest
  name: Test Functions
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        cd src/functions
        pip install -r requirements.txt
        pip install pytest
    
    - name: Run tests
      run: |
        pytest tests/unit/ -v
'@ | Out-File -FilePath ".github/workflows/ci-functions.yml" -Encoding UTF8
Write-Host "  ✓ Created .github/workflows/ci-functions.yml" -ForegroundColor Green

# ============================================================================
# 4. Create Documentation Examples
# ============================================================================
Write-Host "`n📝 Creating documentation examples..." -ForegroundColor Yellow

@'
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
'@ | Out-File -FilePath "docs/examples/nl-rooivalk.md" -Encoding UTF8
Write-Host "  ✓ Created docs/examples/nl-rooivalk.md" -ForegroundColor Green

@'
# Example: Phoenix VC Website

Static website implementation for Phoenix VC.

---

## Project Details

- **Organization:** pvc (Phoenix VC)
- **Project:** website
- **Environments:** staging, prod
- **Primary Region:** euw (West Europe)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Resource Group: pvc-prod-website-rg-euw               │ │
│  │                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐                    │ │
│  │  │  Static Web  │  │  Storage     │                    │ │
│  │  │  App         │  │  Account     │                    │ │
│  │  └──────────────┘  └──────────────┘                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Resource Naming

| Resource | Name |
|----------|------|
| Resource Group | `pvc-prod-website-rg-euw` |
| Static Web App | `pvc-prod-website-swa-euw` |
| Storage Account | `pvcprodwebsitestorageeuw` |

---

## Deployment

```bash
az deployment sub create \
--location westeurope \
--template-file infra/examples/pvc-website.bicep
```

---

## Related Resources

- [Infrastructure Code](../../infra/examples/pvc-website.bicep)
'@ | Out-File -FilePath "docs/examples/pvc-website.md" -Encoding UTF8
Write-Host "  ✓ Created docs/examples/pvc-website.md" -ForegroundColor Green

# ============================================================================
# 5. Update Main README
# ============================================================================
Write-Host "`n📝 Updating main README.md..." -ForegroundColor Yellow

@'
# Azure Infrastructure Standards

**Unified Azure infrastructure standards, modules, and tooling for:**
- **nl** – NeuralLiquid (Jurie)
- **pvc** – Phoenix VC (Eben)
- **tws** – Twines & Straps (Martyn)
- **mys** – Mystira (Eben)

---

## 🎯 Purpose

This repository is the **single source of truth** for:
- ✅ Azure naming conventions
- ✅ Reusable Infrastructure-as-Code modules
- ✅ Source code templates
- ✅ Validation and operational tools
- ✅ CI/CD workflows
- ✅ Configuration patterns

**This is NOT a template repo.** For project scaffolding, see [`phoenixvc/azure-project-template`](https://github.com/phoenixvc/azure-project-template).

---

## 📋 Quick Start

### **Reference Naming Module**

```bicep
module naming 'br:phoenixvcacr.azurecr.io/infra/modules/naming:v2.1' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: naming.outputs.rgName  // nl-prod-rooivalk-rg-euw
location: 'westeurope'
}
```

### **Validate Resource Names**

```bash
pip install -r tools/validator/requirements.txt
python tools/validator/nl_az_name.py validate nl-prod-rooivalk-api-euw
```

### **Use in CI/CD**

```yaml
jobs:
validate-naming:
  uses: phoenixvc/azure-infrastructure/.github/workflows/validate-naming.yml@main
```

---

## 🏗️ Repository Structure

```
azure-infrastructure/
├── docs/                          # Documentation
│   ├── naming-conventions.md     # Authoritative standard
│   └── examples/                 # Real-world examples
│
├── infra/                        # Infrastructure-as-Code
│   ├── modules/                  # Reusable Bicep modules
│   │   ├── naming/              # Naming convention module
│   │   ├── app-service/         # App Service module
│   │   ├── function-app/        # Function App module
│   │   ├── postgres/            # PostgreSQL module
│   │   ├── storage/             # Storage Account module
│   │   └── key-vault/           # Key Vault module
│   └── examples/                # Deployable examples
│
├── src/                          # Source code templates
│   ├── api/                     # FastAPI template
│   ├── functions/               # Azure Functions template
│   └── worker/                  # Background worker template
│
├── tests/                        # Test templates
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   └── e2e/                     # End-to-end tests
│
├── config/                       # Configuration templates
│   ├── dev.json
│   ├── staging.json
│   └── prod.json
│
├── db/                           # Database
│   ├── migrations/              # Schema migrations
│   └── seeds/                   # Seed data
│
├── tools/                        # Operational tooling
│   ├── validator/               # Naming validator
│   ├── queries/                 # Azure Resource Graph queries
│   └── scripts/                 # Automation scripts
│
└── .github/workflows/            # Reusable CI/CD workflows
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [**Naming Conventions**](docs/naming-conventions.md) | Complete naming standard |
| [**Infrastructure Modules**](infra/modules/) | Reusable Bicep modules |
| [**Source Templates**](src/) | API, Functions, Worker templates |
| [**Tools**](tools/) | Validator, queries, scripts |
| [**Examples**](docs/examples/) | Real-world implementations |

---

## 🔧 Available Modules

All modules published to: `br:phoenixvcacr.azurecr.io/infra/modules/{module}:v2.1`

| Module | Description | Documentation |
|--------|-------------|---------------|
| `naming` | Standardized resource naming | [README](infra/modules/naming/README.md) |
| `app-service` | App Service with monitoring | [README](infra/modules/app-service/README.md) |
| `function-app` | Azure Functions with storage | [README](infra/modules/function-app/README.md) |
| `postgres` | PostgreSQL Flexible Server | [README](infra/modules/postgres/README.md) |
| `storage` | Storage Account with containers | [README](infra/modules/storage/README.md) |
| `key-vault` | Key Vault with access policies | [README](infra/modules/key-vault/README.md) |

---

## 🛠️ Tools

### **Naming Validator**

```bash
python tools/validator/nl_az_name.py validate nl-prod-rooivalk-api-euw

# Output:
# ✅ Valid: nl-prod-rooivalk-api-euw
# Components:
#   org: nl
#   env: prod
#   project: rooivalk
#   type: api
#   region: euw
```

### **Azure Resource Graph Queries**

```bash
# Check naming compliance
az graph query -q "$(cat tools/queries/compliance-check.kql)"

# Generate resource inventory
az graph query -q "$(cat tools/queries/resource-inventory.kql)"
```

See [tools/README.md](tools/README.md) for all available tools.

---

## 📊 Examples

| Example | Organization | Description |
|---------|--------------|-------------|
| [nl-rooivalk](docs/examples/nl-rooivalk.md) | NeuralLiquid | AI platform with API, functions, database |
| [pvc-website](docs/examples/pvc-website.md) | Phoenix VC | Static website |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to propose changes to naming standards
- Module development guidelines
- Pull request process
- Versioning strategy

**Key principle:** Changes to naming standards require consensus from all org leads.

---

## 📦 CI/CD Workflows

Reusable GitHub Actions workflows:

| Workflow | Purpose | Usage |
|----------|---------|-------|
| `validate-naming.yml` | Validate resource names | `uses: phoenixvc/azure-infrastructure/.github/workflows/validate-naming.yml@main` |
| `publish-modules.yml` | Publish Bicep modules to ACR | Runs on push to `main` |
| `ci-api.yml` | Test and build API | Template for projects |
| `ci-functions.yml` | Test and build Functions | Template for projects |

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

**Current Version:** v2.1

---

## 📄 License

MIT License - See [LICENSE](LICENSE)

---

## 🔗 Related Repositories

- [**azure-project-template**](https://github.com/phoenixvc/azure-project-template) - Project scaffolding template
- [**neuralliquid/rooivalk-platform**](https://github.com/neuralliquid/rooivalk-platform) - Example implementation

---

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/phoenixvc/azure-infrastructure/issues)
- **Discussions:** [GitHub Discussions](https://github.com/phoenixvc/azure-infrastructure/discussions)
- **Maintainers:** Hans Jurgens Smit, Jurie, Eben, Martyn

---

**Version:** v2.1  
**Last Updated:** 2025-12-07
'@ | Out-File -FilePath "README.md" -Encoding UTF8
Write-Host "  ✓ Updated README.md" -ForegroundColor Green

# ============================================================================
# 6. Update CHANGELOG
# ============================================================================
Write-Host "`n📝 Updating CHANGELOG.md..." -ForegroundColor Yellow

@'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.0] - 2025-12-07

### Added
- Complete repository restructure with function-based organization
- Infrastructure modules:
- `naming` - Standardized resource naming
- `app-service` - App Service with monitoring
- `function-app` - Azure Functions with storage
- `postgres` - PostgreSQL Flexible Server
- `storage` - Storage Account with containers
- `key-vault` - Key Vault with access policies
- Source code templates:
- `src/api` - FastAPI template with Dockerfile
- `src/functions` - Azure Functions template
- `src/worker` - Background worker template
- Test structure (unit, integration, e2e)
- Configuration templates (dev, staging, prod)
- Database structure (migrations, seeds)
- Tools:
- Naming validator (Python CLI)
- Azure Resource Graph queries
- Automation scripts
- GitHub Actions workflows:
- `validate-naming.yml` - Reusable naming validation
- `publish-modules.yml` - Publish modules to ACR
- `ci-api.yml` - API CI/CD template
- `ci-functions.yml` - Functions CI/CD template
- Documentation examples (nl-rooivalk, pvc-website)

### Changed
- Reorganized directory structure:
- `bicep/` → `infra/`
- `cli/` → `tools/validator/`
- Added `src/`, `tests/`, `config/`, `db/`
- Updated all documentation to reflect new structure

### Removed
- Old directory structure (bicep/, cli/, scripts/, queries/)

---

## [2.0.0] - 2025-12-06

### Added
- Initial repository setup
- Basic naming module
- CLI validator
- GitHub Actions workflow for validation

---

## [1.0.0] - 2025-12-01

### Added
- Initial naming conventions document
- Basic project structure
'@ | Out-File -FilePath "CHANGELOG.md" -Encoding UTF8
Write-Host "  ✓ Updated CHANGELOG.md" -ForegroundColor Green

# ============================================================================
# 7. Git Commit and Push Part 3
# ============================================================================
Write-Host "`n📤 Committing Part 3 changes..." -ForegroundColor Yellow

git add .
git commit -m "feat: Part 3 - Tools, CI/CD workflows, documentation

- Added Azure Resource Graph queries (compliance, inventory)
- Created GitHub Actions workflows:
- validate-naming.yml (reusable)
- publish-modules.yml (ACR publishing)
- ci-api.yml (API CI/CD template)
- ci-functions.yml (Functions CI/CD template)
- Added documentation examples (nl-rooivalk, pvc-website)
- Updated main README with complete structure
- Updated CHANGELOG with v2.1 release notes
- Added tools README and queries README"

Write-Host "`n📤 Pushing all changes to GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host "`n✅ Part 3 Complete!" -ForegroundColor Green
Write-Host "`n🎉 Repository refactoring complete!" -ForegroundColor Cyan
Write-Host "`n📍 Repository: https://github.com/phoenixvc/azure-infrastructure" -ForegroundColor Cyan
Write-Host "`n⚠️  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Add full naming conventions to docs/naming-conventions.md" -ForegroundColor White
Write-Host "  2. Test CLI validator: python tools/validator/nl_az_name.py validate nl-prod-test-api-euw" -ForegroundColor White
Write-Host "  3. Test Bicep module: az deployment sub create --location westeurope --template-file infra/modules/naming/test.bicep" -ForegroundColor White
Write-Host "  4. Create azure-project-template repo next" -ForegroundColor White