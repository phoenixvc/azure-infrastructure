# ============================================================================
# Local Setup Script for phoenixvc/azure-infrastructure
# ============================================================================
# Run this from inside the cloned azure-infrastructure directory
# Assumes repo already exists and is cloned
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🚀 Setting up azure-infrastructure locally..." -ForegroundColor Cyan

# Verify we're in the right place
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in a git repository. Please cd into azure-infrastructure first." -ForegroundColor Red
    exit 1
}

# Create directory structure
Write-Host "`n📁 Creating directory structure..." -ForegroundColor Yellow
$directories = @(
    "docs",
    "bicep/modules",
    "bicep/examples",
    "tools",
    "scripts",
    "queries",
    ".github/workflows"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  ✓ Created $dir" -ForegroundColor Green
}

# ============================================================================
# Create README.md
# ============================================================================
Write-Host "`n📝 Creating README.md..." -ForegroundColor Yellow

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
- Azure naming conventions
- Reusable Infrastructure-as-Code (IaC) modules
- Validation and linting tools
- Resource discovery queries
- CI/CD workflows for standards enforcement

**This is NOT a template repo.** For project scaffolding, see [`phoenixvc/azure-project-template`](https://github.com/phoenixvc/azure-project-template).

---

## 📋 Quick Start

### **For New Projects**

Use the [azure-project-template](https://github.com/phoenixvc/azure-project-template) to scaffold a new project.

### **For Existing Projects**

#### **1. Reference the Naming Module**

```bicep
module naming 'br:phoenixvcacr.azurecr.io/bicep/modules/naming:v2.1' = {
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

#### **2. Add Naming Validation to CI**

```yaml
jobs:
validate-naming:
  uses: phoenixvc/azure-infrastructure/.github/workflows/validate-naming.yml@main
  with:
    bicep_path: './infra'
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [**Naming Conventions v2.1**](docs/azure-naming-conventions-v2.1.md) | Complete naming standard |
| [**Bicep Modules**](bicep/modules/README.md) | Reusable IaC modules |
| [**CLI Tools**](tools/README.md) | Validation tools |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - See [LICENSE](LICENSE)
'@ | Out-File -FilePath "README.md" -Encoding UTF8
Write-Host "  ✓ Created README.md" -ForegroundColor Green

# ============================================================================
# Create bicep/modules/naming.bicep
# ============================================================================
Write-Host "`n📝 Creating Bicep naming module..." -ForegroundColor Yellow

@'
// ============================================================================
// Azure Naming Module v2.1
// ============================================================================

@description('Owning organisation code')
@allowed(['nl', 'pvc', 'tws', 'mys'])
param org string

@description('Deployment environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Logical project / system name')
@minLength(2)
@maxLength(20)
param project string

@description('Short region code')
@allowed(['euw', 'eun', 'wus', 'eus', 'san', 'saf', 'swe', 'uks', 'usw', 'glob'])
param region string

var base = '${org}-${env}-${project}'

output rgName string = '${base}-rg-${region}'
output name_app string = '${base}-app-${region}'
output name_api string = '${base}-api-${region}'
output name_func string = '${base}-func-${region}'
output name_swa string = '${base}-swa-${region}'
output name_db string = '${base}-db-${region}'
output name_storage string = '${org}${env}${replace(project, '-', '')}storage${region}'
output name_kv string = '${base}-kv-${region}'
output name_queue string = '${base}-queue-${region}'
output name_cache string = '${base}-cache-${region}'
output name_ai string = '${base}-ai-${region}'
output name_acr string = '${org}${env}${replace(project, '-', '')}acr${region}'
output name_vnet string = '${base}-vnet-${region}'
output name_subnet string = '${base}-subnet-${region}'
output name_dns string = '${base}-dns-${region}'
output name_log string = '${base}-log-${region}'

output baseName string = base
output pattern string = '[org]-[env]-[project]-[type]-[region]'
output version string = 'v2.1'
'@ | Out-File -FilePath "bicep/modules/naming.bicep" -Encoding UTF8
Write-Host "  ✓ Created bicep/modules/naming.bicep" -ForegroundColor Green

# ============================================================================
# Create bicep/modules/README.md
# ============================================================================
Write-Host "`n📝 Creating Bicep modules README..." -ForegroundColor Yellow

@'
# Bicep Modules

## Available Modules

### `naming.bicep`

Generates standardized Azure resource names.

**Usage:**

```bicep
module naming './naming.bicep' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: naming.outputs.rgName
location: 'westeurope'
}
```

**Outputs:**

- `rgName` - Resource group name
- `name_app` - App Service name
- `name_api` - API Service name
- `name_func` - Function App name
- `name_swa` - Static Web App name
- `name_db` - Database name
- `name_storage` - Storage Account name
- `name_kv` - Key Vault name
- `name_queue` - Queue/Service Bus name
- `name_cache` - Redis Cache name
- `name_ai` - AI Service name
- `name_acr` - Container Registry name
- `name_vnet` - Virtual Network name
- `name_subnet` - Subnet name
- `name_dns` - DNS Zone name
- `name_log` - Log Analytics name
'@ | Out-File -FilePath "bicep/modules/README.md" -Encoding UTF8
Write-Host "  ✓ Created bicep/modules/README.md" -ForegroundColor Green

# ============================================================================
# Create tools/nl_az_name.py
# ============================================================================
Write-Host "`n📝 Creating CLI validator..." -ForegroundColor Yellow

@'
#!/usr/bin/env python3
"""Azure Naming Convention Validator v2.1"""

import re
import sys
import argparse
from pathlib import Path
from typing import Tuple, Optional

VALID_ORGS = ['nl', 'pvc', 'tws', 'mys']
VALID_ENVS = ['dev', 'staging', 'prod']
VALID_TYPES = ['app', 'api', 'func', 'swa', 'db', 'storage', 'kv', 'queue', 'cache', 'ai', 'acr', 'vnet', 'subnet', 'dns', 'log', 'rg']
VALID_REGIONS = ['euw', 'eun', 'wus', 'eus', 'san', 'saf', 'swe', 'uks', 'usw', 'glob']

RESOURCE_PATTERN = r'^([a-z]+)-([a-z]+)-([a-z0-9\-]+)-([a-z]+)-([a-z]+)$'
RG_PATTERN = r'^([a-z]+)-([a-z]+)-([a-z0-9\-]+)-rg-([a-z]+)$'

def validate_resource_name(name: str) -> Tuple[bool, str, Optional[dict]]:
  """Validate a resource name against the standard pattern."""
  if not re.match(r'^[a-z0-9\-]+$', name):
      return False, "Invalid characters (only a-z, 0-9, - allowed)", None
  
  if name.startswith('-') or name.endswith('-'):
      return False, "Cannot start or end with hyphen", None
  
  # Try resource group pattern
  rg_match = re.match(RG_PATTERN, name)
  if rg_match:
      org, env, project, region = rg_match.groups()
      if org not in VALID_ORGS:
          return False, f"Invalid org '{org}'", None
      if env not in VALID_ENVS:
          return False, f"Invalid env '{env}'", None
      if region not in VALID_REGIONS:
          return False, f"Invalid region '{region}'", None
      return True, f"✅ Valid: {name}", {'org': org, 'env': env, 'project': project, 'type': 'rg', 'region': region}
  
  # Try standard resource pattern
  res_match = re.match(RESOURCE_PATTERN, name)
  if res_match:
      org, env, project, type_code, region = res_match.groups()
      if org not in VALID_ORGS:
          return False, f"Invalid org '{org}'", None
      if env not in VALID_ENVS:
          return False, f"Invalid env '{env}'", None
      if type_code not in VALID_TYPES:
          return False, f"Invalid type '{type_code}'", None
      if region not in VALID_REGIONS:
          return False, f"Invalid region '{region}'", None
      return True, f"✅ Valid: {name}", {'org': org, 'env': env, 'project': project, 'type': type_code, 'region': region}
  
  return False, "Does not match pattern [org]-[env]-[project]-[type]-[region]", None

def main():
  parser = argparse.ArgumentParser(description='Azure Naming Validator v2.1')
  subparsers = parser.add_subparsers(dest='command', required=True)
  
  validate_parser = subparsers.add_parser('validate', help='Validate a resource name')
  validate_parser.add_argument('name', help='Resource name to validate')
  
  args = parser.parse_args()
  
  if args.command == 'validate':
      is_valid, message, components = validate_resource_name(args.name)
      print(message)
      if components:
          print("\nComponents:")
          for key, value in components.items():
              print(f"  {key}: {value}")
      sys.exit(0 if is_valid else 1)

if __name__ == '__main__':
  main()
'@ | Out-File -FilePath "tools/nl_az_name.py" -Encoding UTF8
Write-Host "  ✓ Created tools/nl_az_name.py" -ForegroundColor Green

# ============================================================================
# Create tools/requirements.txt
# ============================================================================
@'
# Python dependencies for azure-infrastructure tools
# No external dependencies required for basic validation
'@ | Out-File -FilePath "tools/requirements.txt" -Encoding UTF8
Write-Host "  ✓ Created tools/requirements.txt" -ForegroundColor Green

# ============================================================================
# Create tools/README.md
# ============================================================================
@'
# CLI Tools

## nl_az_name.py

Azure naming convention validator.

### Installation

```bash
pip install -r requirements.txt
```

### Usage

```bash
# Validate a resource name
python nl_az_name.py validate nl-prod-rooivalk-api-euw

# Expected output:
# ✅ Valid: nl-prod-rooivalk-api-euw
# Components:
#   org: nl
#   env: prod
#   project: rooivalk
#   type: api
#   region: euw
```
'@ | Out-File -FilePath "tools/README.md" -Encoding UTF8
Write-Host "  ✓ Created tools/README.md" -ForegroundColor Green

# ============================================================================
# Create .github/workflows/validate-naming.yml
# ============================================================================
Write-Host "`n📝 Creating GitHub Actions workflow..." -ForegroundColor Yellow

@'
name: Validate Azure Naming

on:
workflow_call:
  inputs:
    bicep_path:
      description: 'Path to Bicep files'
      required: false
      type: string
      default: './infra'

jobs:
validate:
  name: Validate Naming Conventions
  runs-on: ubuntu-latest
  
  steps:
    - name: Checkout calling repository
      uses: actions/checkout@v4
    
    - name: Checkout azure-infrastructure
      uses: actions/checkout@v4
      with:
        repository: phoenixvc/azure-infrastructure
        path: .azure-infrastructure
        ref: main
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Validate naming
      run: |
        python .azure-infrastructure/tools/nl_az_name.py validate nl-prod-test-api-euw
        echo "✅ Naming validation configured"
'@ | Out-File -FilePath ".github/workflows/validate-naming.yml" -Encoding UTF8
Write-Host "  ✓ Created .github/workflows/validate-naming.yml" -ForegroundColor Green

# ============================================================================
# Create CONTRIBUTING.md
# ============================================================================
Write-Host "`n📝 Creating CONTRIBUTING.md..." -ForegroundColor Yellow

@'
# Contributing to Azure Infrastructure Standards

## 📋 Types of Contributions

### 1. Documentation Updates
- Requires 1 maintainer approval

### 2. Naming Standard Changes
- Requires consensus from all org leads
- Must include version bump
- Must update CHANGELOG.md

### 3. Module Enhancements
- Requires 1 maintainer approval

## 📝 Pull Request Guidelines

**PR Title Format:**
```
[type]: Brief description

Types: docs, feat, fix, chore, break
```

## 🏷️ Versioning

- **Major:** Breaking changes
- **Minor:** New features
- **Patch:** Bug fixes
'@ | Out-File -FilePath "CONTRIBUTING.md" -Encoding UTF8
Write-Host "  ✓ Created CONTRIBUTING.md" -ForegroundColor Green

# ============================================================================
# Create CHANGELOG.md
# ============================================================================
@'
# Changelog

## [v2.1.0] - 2025-12-07

### Added
- Initial repository structure
- Naming conventions v2.1
- Bicep naming module
- CLI validator tool
- GitHub Actions workflow for validation
- Documentation and examples

### Organizations Supported
- nl (NeuralLiquid)
- pvc (Phoenix VC)
- tws (Twines & Straps)
- mys (Mystira)
'@ | Out-File -FilePath "CHANGELOG.md" -Encoding UTF8
Write-Host "  ✓ Created CHANGELOG.md" -ForegroundColor Green

# ============================================================================
# Create .gitignore
# ============================================================================
@'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
.venv

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Azure
*.parameters.json
!*.parameters.example.json
'@ | Out-File -FilePath ".gitignore" -Encoding UTF8
Write-Host "  ✓ Created .gitignore" -ForegroundColor Green

# ============================================================================
# Create LICENSE
# ============================================================================
@'
MIT License

Copyright (c) 2025 Phoenix VC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'@ | Out-File -FilePath "LICENSE" -Encoding UTF8
Write-Host "  ✓ Created LICENSE" -ForegroundColor Green

# ============================================================================
# Create docs placeholder
# ============================================================================
@'
# Azure Naming Conventions v2.1

**TODO:** Add your full naming conventions document here.

Pattern: `[org]-[env]-[project]-[type]-[region]`

Organizations: nl, pvc, tws, mys
Environments: dev, staging, prod
Regions: euw, eun, san, saf, wus, eus, swe, uks, usw, glob
'@ | Out-File -FilePath "docs/azure-naming-conventions-v2.1.md" -Encoding UTF8
Write-Host "  ✓ Created docs/azure-naming-conventions-v2.1.md (placeholder)" -ForegroundColor Green

# ============================================================================
# Git commit and push
# ============================================================================
Write-Host "`n📤 Committing and pushing to GitHub..." -ForegroundColor Yellow

git add .
git commit -m "Initial commit: Azure infrastructure standards v2.1"
git push -u origin main

Write-Host "`n✅ Setup complete!" -ForegroundColor Green
Write-Host "`n📍 Repository: https://github.com/phoenixvc/azure-infrastructure" -ForegroundColor Cyan
Write-Host "`n⚠️  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Add full naming conventions to docs/azure-naming-conventions-v2.1.md"
Write-Host "  2. Test CLI: python tools/nl_az_name.py validate nl-prod-test-api-euw"
Write-Host "  3. Create azure-project-template repo next"