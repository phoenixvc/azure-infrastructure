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
