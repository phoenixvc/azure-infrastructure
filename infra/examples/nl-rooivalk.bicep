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
