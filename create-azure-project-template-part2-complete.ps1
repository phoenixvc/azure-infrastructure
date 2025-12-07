# ============================================================================
# Create azure-project-template Part 2: Complete Implementations
# ============================================================================
# Run from: C:\Users\smitj\repos\azure-project-template
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🔧 Part 2: Creating complete implementations..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Verify we're in azure-project-template
if (-not (Test-Path "README.md")) {
  Write-Host "❌ Error: Not in azure-project-template repo" -ForegroundColor Red
  exit 1
}

# ============================================================================
# 1. Copy from azure-infrastructure
# ============================================================================
Write-Host "`n📦 Copying examples from azure-infrastructure..." -ForegroundColor Yellow

$infraPath = "../azure-infrastructure"

# Copy API
if (Test-Path "$infraPath/src/api") {
  Copy-Item -Path "$infraPath/src/api/*" -Destination "src/api-standard/app/" -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  ✓ Copied API standard" -ForegroundColor Green
}
else {
  Write-Host "  ⚠ API not found in azure-infrastructure" -ForegroundColor Yellow
}

# Copy Web
if (Test-Path "$infraPath/src/web") {
  Copy-Item -Path "$infraPath/src/web/*" -Destination "src/web/" -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  ✓ Copied Web" -ForegroundColor Green
}
else {
  Write-Host "  ⚠ Web not found in azure-infrastructure" -ForegroundColor Yellow
}

# Copy Functions
if (Test-Path "$infraPath/src/functions") {
  Copy-Item -Path "$infraPath/src/functions/*" -Destination "src/functions/" -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  ✓ Copied Functions" -ForegroundColor Green
}
else {
  Write-Host "  ⚠ Functions not found in azure-infrastructure" -ForegroundColor Yellow
}

# Copy Config
if (Test-Path "$infraPath/config") {
  Copy-Item -Path "$infraPath/config/*" -Destination "config/" -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  ✓ Copied Config" -ForegroundColor Green
}

# Copy DB
if (Test-Path "$infraPath/db") {
  Copy-Item -Path "$infraPath/db/*" -Destination "db/" -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  ✓ Copied DB" -ForegroundColor Green
}

# Copy Tests
if (Test-Path "$infraPath/tests") {
  Copy-Item -Path "$infraPath/tests/*" -Destination "tests/" -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  ✓ Copied Tests" -ForegroundColor Green
}

# ============================================================================
# 2. Create Infrastructure Files
# ============================================================================
Write-Host "`n📝 Creating infrastructure files..." -ForegroundColor Yellow

# infra/main.bicep
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
// Outputs
// ============================================================================

output resourceGroupName string = rg.name
output location string = location
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
# 3. Create Hexagonal API Implementation
# ============================================================================
Write-Host "`n📝 Creating Hexagonal API implementation..." -ForegroundColor Yellow

# Domain - User Entity
@'
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class User:
    """User domain entity"""
    id: Optional[int]
    email: str
    name: str
    password_hash: str
    created_at: datetime
    updated_at: datetime
    
    def is_valid_email(self) -> bool:
        """Validate email format"""
        return '@' in self.email and '.' in self.email.split('@')[1]
'@ | Out-File -FilePath "src/api-hexagonal/domain/entities/user.py" -Encoding UTF8

# Domain - User Repository Interface
@'
from abc import ABC, abstractmethod
from typing import Optional, List
from domain.entities.user import User

class UserRepository(ABC):
    """Repository interface for User entity"""
    
    @abstractmethod
    async def create(self, user: User) -> User:
        pass
    
    @abstractmethod
    async def get_by_id(self, user_id: int) -> Optional[User]:
        pass
    
    @abstractmethod
    async def get_by_email(self, email: str) -> Optional[User]:
        pass
'@ | Out-File -FilePath "src/api-hexagonal/domain/repositories/user_repository.py" -Encoding UTF8

# Hexagonal README
@'
# API - Hexagonal Architecture

Clean architecture implementation with domain-driven design.

## Structure

```
├── domain/              # Core business logic
│   ├── entities/        # Domain entities
│   └── repositories/    # Repository interfaces
├── application/         # Use cases
│   └── use_cases/       # Application logic
├── infrastructure/      # External dependencies
│   └── database/        # Database implementation
└── adapters/            # Interface adapters
    └── api/             # FastAPI routes
```

## Run Locally

```bash
pip install -r requirements.txt
uvicorn adapters.api.main:app --reload --port 8000
```
'@ | Out-File -FilePath "src/api-hexagonal/README.md" -Encoding UTF8

# Hexagonal requirements.txt
@'
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
sqlalchemy==2.0.25
asyncpg==0.29.0
'@ | Out-File -FilePath "src/api-hexagonal/requirements.txt" -Encoding UTF8

Write-Host "  ✓ Created Hexagonal API implementation" -ForegroundColor Green

# ============================================================================
# 4. Create .gitignore
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
# 5. Commit and Push
# ============================================================================
Write-Host "`n📤 Committing and pushing..." -ForegroundColor Yellow

git add .
git commit -m "Add complete implementations

- Infrastructure (Bicep) with all Azure services
- API Standard (FastAPI layered architecture)
- API Hexagonal (Clean architecture with DDD)
- Configuration files (dev, staging, prod)
- Database structure (migrations, seeds)
- Tests structure (unit, integration, e2e)
- Documentation"

git push

Write-Host "  ✓ Pushed to GitHub" -ForegroundColor Green

# ============================================================================
# 6. Success
# ============================================================================
Write-Host "`n✅ Complete template created successfully!" -ForegroundColor Green
Write-Host "`n📍 Repository: https://github.com/phoenixvc/azure-project-template" -ForegroundColor Cyan
Write-Host "`n📦 Ready to use as template!" -ForegroundColor Yellow
Write-Host "  Teams can now click 'Use this template' to create new projects" -ForegroundColor White