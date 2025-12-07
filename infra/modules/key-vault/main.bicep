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
