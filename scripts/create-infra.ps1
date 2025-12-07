# Create infrastructure files

$mainBicep = @"
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
param deployRedis bool = false
param deployAppInsights bool = true

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '$${org}-$${env}-$${project}-rg-$${region}'
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
"@

$mainBicep | Out-File -FilePath "infra/main.bicep" -Encoding UTF8

# Dev parameters
$devParams = @"
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
"@

$devParams | Out-File -FilePath "infra/parameters/dev.bicepparam" -Encoding UTF8

# Staging parameters
$stagingParams = @"
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
"@

$stagingParams | Out-File -FilePath "infra/parameters/staging.bicepparam" -Encoding UTF8

# Prod parameters
$prodParams = @"
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
"@

$prodParams | Out-File -FilePath "infra/parameters/prod.bicepparam" -Encoding UTF8

Write-Host "  ✓ Infrastructure files" -ForegroundColor Green
