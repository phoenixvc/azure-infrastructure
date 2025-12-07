// ============================================================================
// Virtual Network Module
// ============================================================================
// Creates a Virtual Network with subnets, NSGs, and monitoring

@description('Virtual Network name (from naming module)')
param vnetName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Virtual Network address space')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet configurations')
param subnets array = [
  {
    name: 'default'
    addressPrefix: '10.0.1.0/24'
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
  }
  {
    name: 'app-service'
    addressPrefix: '10.0.2.0/24'
    serviceEndpoints: [
      { service: 'Microsoft.Web' }
      { service: 'Microsoft.Sql' }
      { service: 'Microsoft.Storage' }
      { service: 'Microsoft.KeyVault' }
    ]
    delegations: [
      {
        name: 'app-service-delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
  }
  {
    name: 'database'
    addressPrefix: '10.0.3.0/24'
    serviceEndpoints: []
    delegations: [
      {
        name: 'postgres-delegation'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
  }
  {
    name: 'private-endpoints'
    addressPrefix: '10.0.4.0/24'
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
  }
]

@description('Enable DDoS protection (production only)')
param enableDdosProtection bool = false

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

// Network Security Group for default subnet
resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${vnetName}-default-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Network Security Group for database subnet
resource nsgDatabase 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${vnetName}-database-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowPostgresFromVnet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5432'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Network Security Group for private endpoints subnet
resource nsgPrivateEndpoints 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${vnetName}-pe-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVnetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    enableDdosProtection: enableDdosProtection
    subnets: [for (subnet, i) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        serviceEndpoints: subnet.serviceEndpoints
        delegations: subnet.delegations
        privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
        networkSecurityGroup: subnet.name == 'default' ? { id: nsgDefault.id } : subnet.name == 'database' ? { id: nsgDatabase.id } : subnet.name == 'private-endpoints' ? { id: nsgPrivateEndpoints.id } : null
      }
    }]
  }
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${vnetName}-diagnostics'
  scope: vnet
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'VMProtectionAlerts'
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
output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetIds object = {
  default: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'default')
  appService: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'app-service')
  database: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'database')
  privateEndpoints: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'private-endpoints')
}
output addressPrefix string = addressPrefix
