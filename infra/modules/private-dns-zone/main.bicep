// ============================================================================
// Private DNS Zone Module
// ============================================================================
// Creates a Private DNS Zone with VNet link for private endpoint resolution

@description('Private DNS Zone name (e.g., privatelink.postgres.database.azure.com)')
param zoneName string

@description('Virtual Network ID to link')
param vnetId string

@description('Virtual Network name for the link name')
param vnetName string

@description('Enable auto-registration of VM DNS records')
param enableAutoRegistration bool = false

@description('Tags to apply to resources')
param tags object = {}

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
  tags: tags
}

// VNet Link
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: enableAutoRegistration
  }
}

output privateDnsZoneId string = privateDnsZone.id
output privateDnsZoneName string = privateDnsZone.name
