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
