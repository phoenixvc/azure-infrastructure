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
