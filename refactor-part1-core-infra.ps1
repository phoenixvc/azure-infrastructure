# ============================================================================
# Part 1: Core Restructure + Infrastructure Modules
# ============================================================================
# Run from: C:\Users\smitj\repos\azure-infrastructure
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🔧 Part 1: Core Restructure + Infrastructure Modules" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Verify we're in the right place
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in azure-infrastructure repo" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 1. Create New Directory Structure
# ============================================================================
Write-Host "`n📁 Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    "infra/modules/naming",
    "infra/modules/app-service",
    "infra/modules/function-app",
    "infra/modules/postgres",
    "infra/modules/storage",
    "infra/modules/key-vault",
    "infra/examples",
    "src/api",
    "src/functions",
    "src/worker",
    "tests/unit",
    "tests/integration",
    "tests/e2e",
    "config",
    "db/migrations",
    "db/seeds",
    "tools/validator",
    "tools/queries",
    "tools/scripts",
    "docs/examples"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  ✓ Created $dir" -ForegroundColor Green
}

# ============================================================================
# 2. Move Existing Files
# ============================================================================
Write-Host "`n📦 Moving existing files..." -ForegroundColor Yellow

# Move bicep modules
if (Test-Path "bicep/modules/naming.bicep") {
    Move-Item "bicep/modules/naming.bicep" "infra/modules/naming/main.bicep" -Force
    Write-Host "  ✓ Moved naming.bicep → infra/modules/naming/main.bicep" -ForegroundColor Green
}

if (Test-Path "bicep/modules/README.md") {
    Move-Item "bicep/modules/README.md" "infra/modules/naming/README.md" -Force
    Write-Host "  ✓ Moved module README" -ForegroundColor Green
}

# Move tools
if (Test-Path "tools/nl_az_name.py") {
    Move-Item "tools/nl_az_name.py" "tools/validator/nl_az_name.py" -Force
    Write-Host "  ✓ Moved validator" -ForegroundColor Green
}

if (Test-Path "tools/requirements.txt") {
    Move-Item "tools/requirements.txt" "tools/validator/requirements.txt" -Force
    Write-Host "  ✓ Moved requirements.txt" -ForegroundColor Green
}

if (Test-Path "tools/README.md") {
    Move-Item "tools/README.md" "tools/validator/README.md" -Force
    Write-Host "  ✓ Moved validator README" -ForegroundColor Green
}

# Move setup script
if (Test-Path "scripts/setup-azure-infra.ps1") {
    Move-Item "scripts/setup-azure-infra.ps1" "tools/scripts/setup-azure-infra.ps1" -Force
    Write-Host "  ✓ Moved setup script" -ForegroundColor Green
}

# Clean up old directories
Remove-Item "bicep" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "cli" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "scripts" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "queries" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "  ✓ Cleaned up old directories" -ForegroundColor Green

# ============================================================================
# 3. Create Naming Module Files
# ============================================================================
Write-Host "`n📝 Creating naming module files..." -ForegroundColor Yellow

# Test file for naming module
@'
// Test file for naming module
targetScope = 'subscription'

module naming 'main.bicep' = {
name: 'naming-test'
params: {
  org: 'nl'
  env: 'dev'
  project: 'test'
  region: 'euw'
}
}

output testResults object = {
rgName: naming.outputs.rgName
apiName: naming.outputs.name_api
funcName: naming.outputs.name_func
storageName: naming.outputs.name_storage
kvName: naming.outputs.name_kv
}
'@ | Out-File -FilePath "infra/modules/naming/test.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/naming/test.bicep" -ForegroundColor Green

# ============================================================================
# 4. Create App Service Module
# ============================================================================
Write-Host "`n📝 Creating App Service module..." -ForegroundColor Yellow

@'
// ============================================================================
// App Service Module
// ============================================================================
// Creates an App Service with App Service Plan, monitoring, and diagnostics

@description('App Service name (from naming module)')
param appName string

@description('Location for resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
@allowed(['F1', 'B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v2', 'P2v2', 'P3v2'])
param sku string = 'B1'

@description('Runtime stack')
@allowed(['DOTNETCORE|8.0', 'PYTHON|3.11', 'NODE|20-lts'])
param runtimeStack string = 'PYTHON|3.11'

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
name: '${appName}-plan'
location: location
tags: tags
sku: {
  name: sku
}
kind: 'linux'
properties: {
  reserved: true
}
}

// App Service
resource appService 'Microsoft.Web/sites@2022-09-01' = {
name: appName
location: location
tags: tags
identity: {
  type: 'SystemAssigned'
}
properties: {
  serverFarmId: appServicePlan.id
  httpsOnly: true
  siteConfig: {
    linuxFxVersion: runtimeStack
    alwaysOn: sku != 'F1'
    ftpsState: 'Disabled'
    minTlsVersion: '1.2'
    http20Enabled: true
    healthCheckPath: '/health'
  }
}
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
name: '${appName}-diagnostics'
scope: appService
properties: {
  workspaceId: logAnalyticsWorkspaceId
  logs: [
    {
      category: 'AppServiceHTTPLogs'
      enabled: true
    }
    {
      category: 'AppServiceConsoleLogs'
      enabled: true
    }
    {
      category: 'AppServiceAppLogs'
      enabled: true
    }
  ]
  metrics: [
    {
      category: 'AllMetrics'
      enabled: true
    }
  ]
}
}

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output principalId string = appService.identity.principalId
'@ | Out-File -FilePath "infra/modules/app-service/main.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/app-service/main.bicep" -ForegroundColor Green

@'
# App Service Module

Creates an Azure App Service with:
- ✅ App Service Plan
- ✅ Managed Identity
- ✅ HTTPS only
- ✅ Health check endpoint
- ✅ Diagnostic logging

---

## Usage

```bicep
module naming '../naming/main.bicep' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

module appService '../app-service/main.bicep' = {
name: 'app-service'
params: {
  appName: naming.outputs.name_api
  location: 'westeurope'
  sku: 'B1'
  runtimeStack: 'PYTHON|3.11'
  logAnalyticsWorkspaceId: logAnalytics.id
  tags: {
    org: 'nl'
    env: 'prod'
    project: 'rooivalk'
  }
}
}
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `appName` | string | - | App Service name (from naming module) |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'B1' | App Service Plan SKU |
| `runtimeStack` | string | 'PYTHON\|3.11' | Runtime stack |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `appServiceId` | string | App Service resource ID |
| `appServiceName` | string | App Service name |
| `appServiceUrl` | string | App Service URL |
| `principalId` | string | Managed Identity principal ID |
'@ | Out-File -FilePath "infra/modules/app-service/README.md" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/app-service/README.md" -ForegroundColor Green

# ============================================================================
# 5. Create Function App Module
# ============================================================================
Write-Host "`n📝 Creating Function App module..." -ForegroundColor Yellow

@'
// ============================================================================
// Function App Module
// ============================================================================
// Creates an Azure Function App with storage and monitoring

@description('Function App name (from naming module)')
param funcName string

@description('Storage Account name (from naming module)')
param storageName string

@description('Location for resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
@allowed(['Y1', 'EP1', 'EP2', 'EP3'])
param sku string = 'Y1'

@description('Runtime stack')
@allowed(['python', 'dotnet', 'node'])
param runtime string = 'python'

@description('Runtime version')
param runtimeVersion string = '3.11'

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// Storage Account for Function App
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
name: storageName
location: location
tags: tags
sku: {
  name: 'Standard_LRS'
}
kind: 'StorageV2'
properties: {
  supportsHttpsTrafficOnly: true
  minimumTlsVersion: 'TLS1_2'
  allowBlobPublicAccess: false
}
}

// App Service Plan (Consumption or Premium)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
name: '${funcName}-plan'
location: location
tags: tags
sku: {
  name: sku
}
kind: 'functionapp'
properties: {
  reserved: true
}
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
name: funcName
location: location
tags: tags
kind: 'functionapp,linux'
identity: {
  type: 'SystemAssigned'
}
properties: {
  serverFarmId: appServicePlan.id
  httpsOnly: true
  siteConfig: {
    linuxFxVersion: '${runtime}|${runtimeVersion}'
    ftpsState: 'Disabled'
    minTlsVersion: '1.2'
    appSettings: [
      {
        name: 'AzureWebJobsStorage'
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
      }
      {
        name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
      }
      {
        name: 'WEBSITE_CONTENTSHARE'
        value: toLower(funcName)
      }
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: runtime
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: ''
      }
    ]
  }
}
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
name: '${funcName}-diagnostics'
scope: functionApp
properties: {
  workspaceId: logAnalyticsWorkspaceId
  logs: [
    {
      category: 'FunctionAppLogs'
      enabled: true
    }
  ]
  metrics: [
    {
      category: 'AllMetrics'
      enabled: true
    }
  ]
}
}

output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output principalId string = functionApp.identity.principalId
output storageAccountId string = storageAccount.id
'@ | Out-File -FilePath "infra/modules/function-app/main.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/function-app/main.bicep" -ForegroundColor Green

@'
# Function App Module

Creates an Azure Function App with:
- ✅ Storage Account
- ✅ App Service Plan (Consumption or Premium)
- ✅ Managed Identity
- ✅ HTTPS only
- ✅ Diagnostic logging

---

## Usage

```bicep
module naming '../naming/main.bicep' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

module functionApp '../function-app/main.bicep' = {
name: 'function-app'
params: {
  funcName: naming.outputs.name_func
  storageName: naming.outputs.name_storage
  location: 'westeurope'
  sku: 'Y1'
  runtime: 'python'
  runtimeVersion: '3.11'
  logAnalyticsWorkspaceId: logAnalytics.id
  tags: {
    org: 'nl'
    env: 'prod'
    project: 'rooivalk'
  }
}
}
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `funcName` | string | - | Function App name |
| `storageName` | string | - | Storage Account name |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'Y1' | App Service Plan SKU (Y1=Consumption) |
| `runtime` | string | 'python' | Runtime stack |
| `runtimeVersion` | string | '3.11' | Runtime version |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `functionAppId` | string | Function App resource ID |
| `functionAppName` | string | Function App name |
| `functionAppUrl` | string | Function App URL |
| `principalId` | string | Managed Identity principal ID |
| `storageAccountId` | string | Storage Account resource ID |
'@ | Out-File -FilePath "infra/modules/function-app/README.md" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/function-app/README.md" -ForegroundColor Green

# ============================================================================
# 6. Create PostgreSQL Module
# ============================================================================
Write-Host "`n📝 Creating PostgreSQL module..." -ForegroundColor Yellow

@'
// ============================================================================
// PostgreSQL Flexible Server Module
// ============================================================================
// Creates a PostgreSQL Flexible Server with backups and monitoring

@description('PostgreSQL server name (from naming module)')
param dbName string

@description('Location for resources')
param location string = resourceGroup().location

@description('PostgreSQL version')
@allowed(['13', '14', '15', '16'])
param postgresVersion string = '16'

@description('SKU name')
@allowed(['Standard_B1ms', 'Standard_B2s', 'Standard_D2s_v3', 'Standard_D4s_v3'])
param skuName string = 'Standard_B1ms'

@description('Storage size in GB')
param storageSizeGB int = 32

@description('Administrator username')
@secure()
param administratorLogin string

@description('Administrator password')
@secure()
param administratorPassword string

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
name: dbName
location: location
tags: tags
sku: {
  name: skuName
  tier: 'Burstable'
}
properties: {
  version: postgresVersion
  administratorLogin: administratorLogin
  administratorLoginPassword: administratorPassword
  storage: {
    storageSizeGB: storageSizeGB
  }
  backup: {
    backupRetentionDays: 7
    geoRedundantBackup: 'Disabled'
  }
  highAvailability: {
    mode: 'Disabled'
  }
}
}

// Firewall rule to allow Azure services
resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = {
parent: postgresServer
name: 'AllowAzureServices'
properties: {
  startIpAddress: '0.0.0.0'
  endIpAddress: '0.0.0.0'
}
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
name: '${dbName}-diagnostics'
scope: postgresServer
properties: {
  workspaceId: logAnalyticsWorkspaceId
  logs: [
    {
      category: 'PostgreSQLLogs'
      enabled: true
    }
  ]
  metrics: [
    {
      category: 'AllMetrics'
      enabled: true
    }
  ]
}
}

output postgresServerId string = postgresServer.id
output postgresServerName string = postgresServer.name
output postgresServerFqdn string = postgresServer.properties.fullyQualifiedDomainName
'@ | Out-File -FilePath "infra/modules/postgres/main.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/postgres/main.bicep" -ForegroundColor Green

@'
# PostgreSQL Flexible Server Module

Creates a PostgreSQL Flexible Server with:
- ✅ Configurable version (13-16)
- ✅ Automated backups (7-day retention)
- ✅ Firewall rules
- ✅ Diagnostic logging

---

## Usage

```bicep
module naming '../naming/main.bicep' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

module postgres '../postgres/main.bicep' = {
name: 'postgres'
params: {
  dbName: naming.outputs.name_db
  location: 'westeurope'
  postgresVersion: '16'
  skuName: 'Standard_B1ms'
  storageSizeGB: 32
  administratorLogin: 'dbadmin'
  administratorPassword: keyVault.getSecret('db-admin-password')
  logAnalyticsWorkspaceId: logAnalytics.id
  tags: {
    org: 'nl'
    env: 'prod'
    project: 'rooivalk'
  }
}
}
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `dbName` | string | - | PostgreSQL server name |
| `location` | string | resourceGroup().location | Azure region |
| `postgresVersion` | string | '16' | PostgreSQL version |
| `skuName` | string | 'Standard_B1ms' | SKU name |
| `storageSizeGB` | int | 32 | Storage size in GB |
| `administratorLogin` | string (secure) | - | Admin username |
| `administratorPassword` | string (secure) | - | Admin password |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `postgresServerId` | string | PostgreSQL server resource ID |
| `postgresServerName` | string | PostgreSQL server name |
| `postgresServerFqdn` | string | PostgreSQL server FQDN |
'@ | Out-File -FilePath "infra/modules/postgres/README.md" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/postgres/README.md" -ForegroundColor Green

# ============================================================================
# 7. Create Storage Module
# ============================================================================
Write-Host "`n📝 Creating Storage Account module..." -ForegroundColor Yellow

@'
// ============================================================================
// Storage Account Module
// ============================================================================
// Creates a Storage Account with containers and monitoring

@description('Storage Account name (from naming module)')
param storageName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Storage Account SKU')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_ZRS', 'Premium_LRS'])
param sku string = 'Standard_LRS'

@description('Container names to create')
param containerNames array = []

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
name: storageName
location: location
tags: tags
sku: {
  name: sku
}
kind: 'StorageV2'
properties: {
  supportsHttpsTrafficOnly: true
  minimumTlsVersion: 'TLS1_2'
  allowBlobPublicAccess: false
  networkAcls: {
    defaultAction: 'Allow'
    bypass: 'AzureServices'
  }
}
}

// Blob Service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
parent: storageAccount
name: 'default'
}

// Containers
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for containerName in containerNames: {
parent: blobService
name: containerName
properties: {
  publicAccess: 'None'
}
}]

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
name: '${storageName}-diagnostics'
scope: blobService
properties: {
  workspaceId: logAnalyticsWorkspaceId
  logs: [
    {
      category: 'StorageRead'
      enabled: true
    }
    {
      category: 'StorageWrite'
      enabled: true
    }
    {
      category: 'StorageDelete'
      enabled: true
    }
  ]
  metrics: [
    {
      category: 'Transaction'
      enabled: true
    }
  ]
}
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
'@ | Out-File -FilePath "infra/modules/storage/main.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/storage/main.bicep" -ForegroundColor Green

@'
# Storage Account Module

Creates a Storage Account with:
- ✅ Blob containers
- ✅ HTTPS only
- ✅ Private access (no public blobs)
- ✅ Diagnostic logging

---

## Usage

```bicep
module naming '../naming/main.bicep' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

module storage '../storage/main.bicep' = {
name: 'storage'
params: {
  storageName: naming.outputs.name_storage
  location: 'westeurope'
  sku: 'Standard_LRS'
  containerNames: ['uploads', 'processed', 'archive']
  logAnalyticsWorkspaceId: logAnalytics.id
  tags: {
    org: 'nl'
    env: 'prod'
    project: 'rooivalk'
  }
}
}
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `storageName` | string | - | Storage Account name |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'Standard_LRS' | Storage Account SKU |
| `containerNames` | array | [] | Blob container names to create |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `storageAccountId` | string | Storage Account resource ID |
| `storageAccountName` | string | Storage Account name |
| `primaryEndpoints` | object | Primary endpoints (blob, file, queue, table) |
'@ | Out-File -FilePath "infra/modules/storage/README.md" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/storage/README.md" -ForegroundColor Green

# ============================================================================
# 8. Create Key Vault Module
# ============================================================================
Write-Host "`n📝 Creating Key Vault module..." -ForegroundColor Yellow

@'
// ============================================================================
// Key Vault Module
// ============================================================================
// Creates a Key Vault with access policies and monitoring

@description('Key Vault name (from naming module)')
param kvName string

@description('Location for resources')
param location string = resourceGroup().location

@description('SKU name')
@allowed(['standard', 'premium'])
param skuName string = 'standard'

@description('Principal IDs to grant access (managed identities)')
param principalIds array = []

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
name: kvName
location: location
tags: tags
properties: {
  sku: {
    family: 'A'
    name: skuName
  }
  tenantId: subscription().tenantId
  enableRbacAuthorization: false
  enableSoftDelete: true
  softDeleteRetentionInDays: 90
  enablePurgeProtection: true
  networkAcls: {
    defaultAction: 'Allow'
    bypass: 'AzureServices'
  }
  accessPolicies: [for principalId in principalIds: {
    tenantId: subscription().tenantId
    objectId: principalId
    permissions: {
      keys: ['get', 'list']
      secrets: ['get', 'list']
      certificates: ['get', 'list']
    }
  }]
}
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
name: '${kvName}-diagnostics'
scope: keyVault
properties: {
  workspaceId: logAnalyticsWorkspaceId
  logs: [
    {
      category: 'AuditEvent'
      enabled: true
    }
  ]
  metrics: [
    {
      category: 'AllMetrics'
      enabled: true
    }
  ]
}
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
'@ | Out-File -FilePath "infra/modules/key-vault/main.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/key-vault/main.bicep" -ForegroundColor Green

@'
# Key Vault Module

Creates a Key Vault with:
- ✅ Soft delete enabled (90-day retention)
- ✅ Purge protection
- ✅ Access policies for managed identities
- ✅ Audit logging

---

## Usage

```bicep
module naming '../naming/main.bicep' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

module keyVault '../key-vault/main.bicep' = {
name: 'key-vault'
params: {
  kvName: naming.outputs.name_kv
  location: 'westeurope'
  skuName: 'standard'
  principalIds: [
    appService.outputs.principalId
    functionApp.outputs.principalId
  ]
  logAnalyticsWorkspaceId: logAnalytics.id
  tags: {
    org: 'nl'
    env: 'prod'
    project: 'rooivalk'
  }
}
}
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `kvName` | string | - | Key Vault name |
| `location` | string | resourceGroup().location | Azure region |
| `skuName` | string | 'standard' | SKU (standard or premium) |
| `principalIds` | array | [] | Managed identity principal IDs to grant access |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `keyVaultId` | string | Key Vault resource ID |
| `keyVaultName` | string | Key Vault name |
| `keyVaultUri` | string | Key Vault URI |
'@ | Out-File -FilePath "infra/modules/key-vault/README.md" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/key-vault/README.md" -ForegroundColor Green

# ============================================================================
# 9. Create Infrastructure Examples
# ============================================================================
Write-Host "`n📝 Creating infrastructure examples..." -ForegroundColor Yellow

@'
// ============================================================================
// Example: NeuralLiquid Rooivalk Platform
// ============================================================================
// Complete infrastructure deployment
// Usage: az deployment sub create --location westeurope --template-file nl-rooivalk.bicep

targetScope = 'subscription'

// Parameters
param location string = 'westeurope'
param dbAdminLogin string = 'dbadmin'

@secure()
param dbAdminPassword string

// Naming
module naming '../modules/naming/main.bicep' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: naming.outputs.rgName
location: location
tags: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  managedBy: 'bicep'
}
}

// Log Analytics Workspace
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.1.0' = {
scope: rg
name: 'log-analytics'
params: {
  name: naming.outputs.name_log
  location: location
}
}

// Storage Account
module storage '../modules/storage/main.bicep' = {
scope: rg
name: 'storage'
params: {
  storageName: naming.outputs.name_storage
  location: location
  containerNames: ['uploads', 'processed', 'archive']
  logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
  tags: rg.tags
}
}

// PostgreSQL Database
module postgres '../modules/postgres/main.bicep' = {
scope: rg
name: 'postgres'
params: {
  dbName: naming.outputs.name_db
  location: location
  administratorLogin: dbAdminLogin
  administratorPassword: dbAdminPassword
  logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
  tags: rg.tags
}
}

// API App Service
module apiService '../modules/app-service/main.bicep' = {
scope: rg
name: 'api-service'
params: {
  appName: naming.outputs.name_api
  location: location
  sku: 'B1'
  runtimeStack: 'PYTHON|3.11'
  logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
  tags: rg.tags
}
}

// Function App
module functionApp '../modules/function-app/main.bicep' = {
scope: rg
name: 'function-app'
params: {
  funcName: naming.outputs.name_func
  storageName: '${naming.outputs.name_storage}func'
  location: location
  runtime: 'python'
  runtimeVersion: '3.11'
  logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
  tags: rg.tags
}
}

// Key Vault
module keyVault '../modules/key-vault/main.bicep' = {
scope: rg
name: 'key-vault'
params: {
  kvName: naming.outputs.name_kv
  location: location
  principalIds: [
    apiService.outputs.principalId
    functionApp.outputs.principalId
  ]
  logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
  tags: rg.tags
}
}

// Outputs
output resourceGroupName string = rg.name
output apiUrl string = apiService.outputs.appServiceUrl
output functionAppUrl string = functionApp.outputs.functionAppUrl
output postgresServerFqdn string = postgres.outputs.postgresServerFqdn
output keyVaultUri string = keyVault.outputs.keyVaultUri
'@ | Out-File -FilePath "infra/examples/nl-rooivalk.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/examples/nl-rooivalk.bicep" -ForegroundColor Green

@'
// ============================================================================
// Example: Phoenix VC Website
// ============================================================================
// Static website infrastructure
// Usage: az deployment sub create --location westeurope --template-file pvc-website.bicep

targetScope = 'subscription'

param location string = 'westeurope'

// Naming
module naming '../modules/naming/main.bicep' = {
name: 'naming'
params: {
  org: 'pvc'
  env: 'prod'
  project: 'website'
  region: 'euw'
}
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: naming.outputs.rgName
location: location
tags: {
  org: 'pvc'
  env: 'prod'
  project: 'website'
  managedBy: 'bicep'
}
}

// Log Analytics Workspace
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.1.0' = {
scope: rg
name: 'log-analytics'
params: {
  name: naming.outputs.name_log
  location: location
}
}

// Storage Account for static website
module storage '../modules/storage/main.bicep' = {
scope: rg
name: 'storage'
params: {
  storageName: naming.outputs.name_storage
  location: location
  containerNames: ['$web', 'assets']
  logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
  tags: rg.tags
}
}

output resourceGroupName string = rg.name
output storageAccountName string = storage.outputs.storageAccountName
output websiteUrl string = storage.outputs.primaryEndpoints.web
'@ | Out-File -FilePath "infra/examples/pvc-website.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/examples/pvc-website.bicep" -ForegroundColor Green

# ============================================================================
# 10. Git Commit Part 1
# ============================================================================
Write-Host "`n📤 Committing Part 1 changes..." -ForegroundColor Yellow

git add .
git commit -m "refactor: Part 1 - Core restructure + infrastructure modules

- Reorganized directory structure (infra/, tools/, src/, tests/, config/, db/)
- Created common Bicep modules:
- naming: Standardized resource naming
- app-service: App Service with monitoring
- function-app: Azure Functions with storage
- postgres: PostgreSQL Flexible Server
- storage: Storage Account with containers
- key-vault: Key Vault with access policies
- Added infrastructure examples (nl-rooivalk, pvc-website)
- Moved existing files to new structure"

Write-Host "`n✅ Part 1 Complete!" -ForegroundColor Green
Write-Host "`n📍 Next: Run refactor-part2-src-tests-config.ps1" -ForegroundColor Cyan