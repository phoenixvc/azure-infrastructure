// ============================================================================
// PostgreSQL Flexible Server Module
// ============================================================================
// Creates a PostgreSQL Flexible Server with backups and monitoring

@description('PostgreSQL server name (from naming module)')
param dbName string

@description('Location for resources')
param location string = resourceGroup().location

@description('PostgreSQL version')
@allowed(['13', '14', '15', '16'])
param postgresVersion string = '16'

@description('SKU name')
@allowed(['Standard_B1ms', 'Standard_B2s', 'Standard_D2s_v3', 'Standard_D4s_v3'])
param skuName string = 'Standard_B1ms'

@description('Storage size in GB')
param storageSizeGB int = 32

@description('Administrator username')
@secure()
param administratorLogin string

@description('Administrator password')
@secure()
param administratorPassword string

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources')
param tags object = {}

@description('Delegated subnet ID for VNet integration (optional)')
param delegatedSubnetId string = ''

@description('Private DNS zone ID for VNet integration (optional)')
param privateDnsZoneId string = ''

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: dbName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: 'Burstable'
  }
  properties: {
    version: postgresVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: !empty(delegatedSubnetId) ? {
      delegatedSubnetResourceId: delegatedSubnetId
      privateDnsZoneArmResourceId: privateDnsZoneId
    } : {}
  }
}

// Firewall rule to allow Azure services (only when not using VNet)
resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = if (empty(delegatedSubnetId)) {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
name: '${dbName}-diagnostics'
scope: postgresServer
properties: {
  workspaceId: logAnalyticsWorkspaceId
  logs: [
    {
      category: 'PostgreSQLLogs'
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

output postgresServerId string = postgresServer.id
output postgresServerName string = postgresServer.name
output postgresServerFqdn string = postgresServer.properties.fullyQualifiedDomainName
