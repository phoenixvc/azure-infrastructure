# ============================================================================
# Add Implementations to azure-project-template
# ============================================================================
# Run from: C:\Users\smitj\repos\azure-infrastructure
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🔧 Adding implementation files..." -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Verify we're in azure-infrastructure
if (-not (Test-Path "infra/modules/naming")) {
    Write-Host "❌ Error: Not in azure-infrastructure repo" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Location verified" -ForegroundColor Green

# Navigate to azure-project-template
$templatePath = "../azure-project-template"
if (-not (Test-Path $templatePath)) {
    Write-Host "❌ Error: azure-project-template not found at $templatePath" -ForegroundColor Red
    exit 1
}

cd $templatePath

# ============================================================================
# Create directory structure
# ============================================================================
Write-Host "`n📁 Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    "infra/parameters",
    "src/api-hexagonal/domain/entities",
    "src/api-hexagonal/domain/repositories"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✓ Created $dir" -ForegroundColor Green
    }
}

# ============================================================================
# Create infrastructure files
# ============================================================================
Write-Host "`n📝 Creating infrastructure..." -ForegroundColor Yellow

$mainBicep = @'
// ============================================================================
// Main Infrastructure Deployment
// ============================================================================

targetScope = 'subscription'

@description('Organization code')
@allowed(['nl', 'pvc', 'tws', 'mys'])
param org string

@description('Environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Project name')
@minLength(2)
@maxLength(20)
param project string

@description('Azure region code')
@allowed(['euw', 'eus', 'wus', 'san', 'saf'])
param region string

@description('Azure location')
param location string = 'westeurope'

param deployApi bool = true
param deployWeb bool = true
param deployFunctions bool = false
param deployDatabase bool = true
param deployStorage bool = true
param deployKeyVault bool = true

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

output resourceGroupName string = rg.name
output location string = location
'@

$mainBicep | Out-File -FilePath "infra/main.bicep" -Encoding UTF8
Write-Host "  ✓ infra/main.bicep" -ForegroundColor Green

# Dev parameters
$devParams = @'
using '../main.bicep'

param org = 'nl'
param env = 'dev'
param project = 'myproject'
param region = 'euw'
param location = 'westeurope'
'@

$devParams | Out-File -FilePath "infra/parameters/dev.bicepparam" -Encoding UTF8
Write-Host "  ✓ infra/parameters/dev.bicepparam" -ForegroundColor Green

# ============================================================================
# Create Hexagonal API
# ============================================================================
Write-Host "`n📝 Creating Hexagonal API..." -ForegroundColor Yellow

$userEntity = @'
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
        return '@' in self.email and '.' in self.email.split('@')[1]
'@

$userEntity | Out-File -FilePath "src/api-hexagonal/domain/entities/user.py" -Encoding UTF8
Write-Host "  ✓ User entity" -ForegroundColor Green

# ============================================================================
# Commit
# ============================================================================
Write-Host "`n📤 Committing..." -ForegroundColor Yellow

git add .
git commit -m "Add implementations"
git push

Write-Host "`n✅ Done!" -ForegroundColor Green
Write-Host "📍 https://github.com/phoenixvc/azure-project-template" -ForegroundColor Cyan
