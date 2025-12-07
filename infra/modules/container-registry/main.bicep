// ============================================================================
// Container Registry Module
// ============================================================================
// Creates an Azure Container Registry with security and monitoring

@description('Container Registry name (from naming module)')
param acrName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Container Registry SKU')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Enable admin user')
param adminUserEnabled bool = false

@description('Enable public network access')
param publicNetworkAccess bool = true

@description('Enable zone redundancy (Premium only)')
param zoneRedundancy bool = false

@description('Retention days for untagged manifests (Premium only)')
param retentionDays int = 7

@description('Principal IDs to grant AcrPull role')
param acrPullPrincipalIds array = []

@description('Principal IDs to grant AcrPush role')
param acrPushPrincipalIds array = []

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
    zoneRedundancy: sku == 'Premium' && zoneRedundancy ? 'Enabled' : 'Disabled'
    policies: sku == 'Premium' ? {
      retentionPolicy: {
        status: 'enabled'
        days: retentionDays
      }
      trustPolicy: {
        status: 'enabled'
        type: 'Notary'
      }
    } : {}
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
  }
}

// AcrPull Role Assignments
resource acrPullRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in acrPullPrincipalIds: {
  name: guid(acr.id, principalId, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

// AcrPush Role Assignments
resource acrPushRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in acrPushPrincipalIds: {
  name: guid(acr.id, principalId, '8311e382-0749-4cb8-b61a-304f252e45ec')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${acrName}-diagnostics'
  scope: acr
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
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

// Outputs
output acrId string = acr.id
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
