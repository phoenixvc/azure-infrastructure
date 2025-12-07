// ============================================================================
// Example: Phoenix VC Website
// ============================================================================
// Static website infrastructure with Static Web App
// Usage: az deployment sub create --location westeurope --template-file pvc-website.bicep

targetScope = 'subscription'

param location string = 'westeurope'
param githubToken string = ''

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

// Static Web App
module swa '../modules/static-web-app/main.bicep' = {
scope: rg
name: 'static-web-app'
params: {
  swaName: naming.outputs.name_swa
  location: location
  sku: 'Standard'
  repositoryUrl: 'https://github.com/phoenixvc/website'
  repositoryBranch: 'main'
  repositoryToken: githubToken
  appLocation: '/'
  outputLocation: 'dist'
  tags: rg.tags
}
}

// Storage Account (for additional assets/backups)
module storage '../modules/storage/main.bicep' = {
scope: rg
name: 'storage'
params: {
  storageName: naming.outputs.name_storage
  location: location
  containerNames: ['assets', 'backups']
  logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
  tags: rg.tags
}
}

output resourceGroupName string = rg.name
output swaName string = swa.outputs.staticWebAppName
output swaUrl string = swa.outputs.staticWebAppUrl
output storageAccountName string = storage.outputs.storageAccountName
