// ============================================================================
// Main Infrastructure Orchestrator
// ============================================================================
// Deploys complete Azure infrastructure using reusable modules
// Usage: az deployment sub create --location westeurope --template-file main.bicep --parameters main.bicepparam
//
// This orchestrator composes all modules to create:
// - Resource Group with consistent naming
// - Log Analytics Workspace with Application Insights
// - Virtual Network with NSGs and subnets
// - PostgreSQL Flexible Server
// - Storage Account with containers
// - Key Vault for secrets
// - Container Registry for Docker images
// - App Service for API
// - Function App for background processing
// - Static Web App for frontend (optional)

targetScope = 'subscription'

// ============================================================================
// Parameters
// ============================================================================

@description('Organization code')
@allowed(['nl', 'pvc', 'tws', 'mys'])
param org string

@description('Deployment environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Project/system name')
@minLength(2)
@maxLength(20)
param project string

@description('Azure region')
@allowed(['westeurope', 'northeurope', 'eastus', 'westus2'])
param location string = 'westeurope'

@description('Short region code for naming')
@allowed(['euw', 'eun', 'wus', 'eus', 'san', 'saf', 'swe', 'uks', 'usw', 'glob'])
param region string = 'euw'

@description('Database administrator login')
param dbAdminLogin string = 'dbadmin'

@description('Database administrator password')
@secure()
param dbAdminPassword string

@description('App Service SKU')
@allowed(['F1', 'B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v2', 'P2v2', 'P3v2'])
param appServiceSku string = 'B1'

@description('Runtime stack for App Service')
@allowed(['DOTNETCORE|8.0', 'PYTHON|3.11', 'NODE|20-lts'])
param runtimeStack string = 'PYTHON|3.11'

@description('Container Registry SKU')
@allowed(['Basic', 'Standard', 'Premium'])
param acrSku string = 'Basic'

@description('Enable VNet integration')
param enableVnet bool = false

@description('Enable DDoS protection (production only)')
param enableDdosProtection bool = false

@description('Storage containers to create')
param storageContainers array = ['uploads', 'processed', 'archive']

@description('Log retention in days')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 30

@description('Enable Static Web App for frontend')
param enableStaticWebApp bool = false

// ============================================================================
// Naming Module
// ============================================================================

module naming 'modules/naming/main.bicep' = {
  name: 'naming'
  params: {
    org: org
    env: env
    project: project
    region: region
  }
}

// ============================================================================
// Resource Group
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: naming.outputs.rgName
  location: location
  tags: {
    org: org
    env: env
    project: project
    managedBy: 'bicep'
    createdAt: utcNow('yyyy-MM-dd')
  }
}

// ============================================================================
// Log Analytics & Application Insights
// ============================================================================

module logAnalytics 'modules/log-analytics/main.bicep' = {
  scope: rg
  name: 'log-analytics'
  params: {
    logAnalyticsName: naming.outputs.name_log
    location: location
    retentionInDays: logRetentionDays
    enableApplicationInsights: true
    appInsightsName: naming.outputs.name_ai
    tags: rg.tags
  }
}

// ============================================================================
// Virtual Network (Optional)
// ============================================================================

module vnet 'modules/vnet/main.bicep' = if (enableVnet) {
  scope: rg
  name: 'vnet'
  params: {
    vnetName: naming.outputs.name_vnet
    location: location
    enableDdosProtection: enableDdosProtection
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
    tags: rg.tags
  }
}

// ============================================================================
// Private DNS Zone for PostgreSQL (when VNet enabled)
// ============================================================================

module postgresDnsZone 'modules/private-dns-zone/main.bicep' = if (enableVnet) {
  scope: rg
  name: 'postgres-dns-zone'
  params: {
    zoneName: 'privatelink.postgres.database.azure.com'
    vnetId: enableVnet ? vnet.outputs.vnetId : ''
    vnetName: naming.outputs.name_vnet
    tags: rg.tags
  }
}

// ============================================================================
// Storage Account
// ============================================================================

module storage 'modules/storage/main.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    storageName: naming.outputs.name_storage
    location: location
    containerNames: storageContainers
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
    tags: rg.tags
  }
}

// ============================================================================
// PostgreSQL Database
// ============================================================================

module postgres 'modules/postgres/main.bicep' = {
  scope: rg
  name: 'postgres'
  params: {
    dbName: naming.outputs.name_db
    location: location
    administratorLogin: dbAdminLogin
    administratorPassword: dbAdminPassword
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
    delegatedSubnetId: enableVnet ? vnet.outputs.subnetIds.database : ''
    privateDnsZoneId: enableVnet ? postgresDnsZone.outputs.privateDnsZoneId : ''
    tags: rg.tags
  }
}

// ============================================================================
// Key Vault (created early to store secrets)
// ============================================================================

module keyVault 'modules/key-vault/main.bicep' = {
  scope: rg
  name: 'key-vault'
  params: {
    kvName: naming.outputs.name_kv
    location: location
    principalIds: [
      apiService.outputs.principalId
      functionApp.outputs.principalId
    ]
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
    secrets: {
      'db-admin-password': dbAdminPassword
      'db-connection-string': 'postgresql://${dbAdminLogin}:${dbAdminPassword}@${postgres.outputs.postgresServerFqdn}:5432/postgres?sslmode=require'
    }
    tags: rg.tags
  }
}

// ============================================================================
// Container Registry
// ============================================================================

module acr 'modules/container-registry/main.bicep' = {
  scope: rg
  name: 'container-registry'
  params: {
    acrName: naming.outputs.name_acr
    location: location
    sku: acrSku
    acrPullPrincipalIds: [
      apiService.outputs.principalId
    ]
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
    tags: rg.tags
  }
}

// ============================================================================
// App Service (API)
// ============================================================================

module apiService 'modules/app-service/main.bicep' = {
  scope: rg
  name: 'api-service'
  params: {
    appName: naming.outputs.name_api
    location: location
    sku: appServiceSku
    runtimeStack: runtimeStack
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
    subnetId: enableVnet ? vnet.outputs.subnetIds.appService : ''
    appInsightsConnectionString: logAnalytics.outputs.appInsightsConnectionString
    appSettings: [
      {
        name: 'DATABASE_URL'
        value: '@Microsoft.KeyVault(VaultName=${naming.outputs.name_kv};SecretName=db-connection-string)'
      }
      {
        name: 'AZURE_KEY_VAULT_URL'
        value: 'https://${naming.outputs.name_kv}${environment().suffixes.keyvaultDns}'
      }
      {
        name: 'AZURE_STORAGE_ACCOUNT_NAME'
        value: naming.outputs.name_storage
      }
    ]
    tags: rg.tags
  }
}

// ============================================================================
// Function App
// ============================================================================

// Function App storage name (must be <=24 chars, alphanumeric only)
var funcStorageName = take('${org}${env}${replace(project, '-', '')}func${region}', 24)

module functionApp 'modules/function-app/main.bicep' = {
  scope: rg
  name: 'function-app'
  params: {
    funcName: naming.outputs.name_func
    storageName: funcStorageName
    location: location
    runtime: 'python'
    runtimeVersion: '3.11'
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
    appInsightsConnectionString: logAnalytics.outputs.appInsightsConnectionString
    tags: rg.tags
  }
}

// ============================================================================
// Static Web App (Optional)
// ============================================================================

module staticWebApp 'modules/static-web-app/main.bicep' = if (enableStaticWebApp) {
  scope: rg
  name: 'static-web-app'
  params: {
    swaName: naming.outputs.name_swa
    location: location
    tags: rg.tags
  }
}

// ============================================================================
// Outputs
// ============================================================================

output resourceGroupName string = rg.name
output resourceGroupId string = rg.id

// Compute
output apiUrl string = apiService.outputs.appServiceUrl
output apiPrincipalId string = apiService.outputs.principalId
output functionAppUrl string = functionApp.outputs.functionAppUrl
output functionAppPrincipalId string = functionApp.outputs.principalId
output staticWebAppUrl string = enableStaticWebApp ? staticWebApp.outputs.staticWebAppUrl : ''

// Data
output postgresServerFqdn string = postgres.outputs.postgresServerFqdn
output storageAccountName string = storage.outputs.storageAccountName

// Security
output keyVaultUri string = keyVault.outputs.keyVaultUri
output acrLoginServer string = acr.outputs.acrLoginServer

// Monitoring
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId
output appInsightsConnectionString string = logAnalytics.outputs.appInsightsConnectionString

// Networking
output vnetId string = enableVnet ? vnet.outputs.vnetId : ''

// Naming pattern used
output namingPattern string = naming.outputs.pattern
output namingVersion string = naming.outputs.version
