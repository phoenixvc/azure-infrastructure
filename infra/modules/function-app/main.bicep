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

@description('Application Insights connection string (optional)')
param appInsightsConnectionString string = ''

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
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsightsConnectionString
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
