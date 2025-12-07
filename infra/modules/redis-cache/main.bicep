// Azure Redis Cache Module
// Provides a managed Redis instance for caching and session management

@description('Redis cache name')
param redisName string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('SKU name: Basic, Standard, or Premium')
@allowed(['Basic', 'Standard', 'Premium'])
param skuName string = 'Standard'

@description('SKU family: C (Basic/Standard) or P (Premium)')
@allowed(['C', 'P'])
param skuFamily string = 'C'

@description('Cache capacity (0-6 for Basic/Standard, 1-5 for Premium)')
@minValue(0)
@maxValue(6)
param capacity int = 1

@description('Enable non-SSL port (not recommended for production)')
param enableNonSslPort bool = false

@description('Minimum TLS version')
@allowed(['1.0', '1.1', '1.2'])
param minimumTlsVersion string = '1.2'

@description('Enable Azure Active Directory authentication')
param enableAadAuth bool = false

@description('Redis version')
@allowed(['4', '6'])
param redisVersion string = '6'

@description('Tags to apply to resources')
param tags object = {}

@description('VNet subnet ID for private endpoint (Premium only)')
param subnetId string = ''

@description('Enable public network access')
param publicNetworkAccess string = 'Enabled'

@description('Redis configuration settings')
param redisConfiguration object = {
  'maxmemory-policy': 'volatile-lru'
  'maxmemory-reserved': '50'
  'maxfragmentationmemory-reserved': '50'
}

// Redis Cache resource
resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisName
  location: location
  tags: tags
  properties: {
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    redisVersion: redisVersion
    sku: {
      name: skuName
      family: skuFamily
      capacity: capacity
    }
    redisConfiguration: redisConfiguration
    // VNet integration for Premium SKU
    subnetId: skuName == 'Premium' && !empty(subnetId) ? subnetId : null
  }
}

// Firewall rules (only when public access is enabled)
resource firewallAllowAzure 'Microsoft.Cache/redis/firewallRules@2023-08-01' = if (publicNetworkAccess == 'Enabled') {
  parent: redisCache
  name: 'AllowAzureServices'
  properties: {
    startIP: '0.0.0.0'
    endIP: '0.0.0.0'
  }
}

// Diagnostic settings (optional - requires Log Analytics workspace)
// Uncomment and add workspaceId parameter to enable
// resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: '${redisName}-diagnostics'
//   scope: redisCache
//   properties: {
//     workspaceId: workspaceId
//     metrics: [
//       {
//         category: 'AllMetrics'
//         enabled: true
//       }
//     ]
//   }
// }

// Outputs
@description('Redis cache resource ID')
output redisCacheId string = redisCache.id

@description('Redis cache name')
output redisCacheName string = redisCache.name

@description('Redis hostname')
output redisHostName string = redisCache.properties.hostName

@description('Redis SSL port')
output redisSslPort int = redisCache.properties.sslPort

@description('Redis primary connection string')
@secure()
output redisPrimaryConnectionString string = '${redisCache.properties.hostName}:${redisCache.properties.sslPort},password=${redisCache.listKeys().primaryKey},ssl=True,abortConnect=False'

@description('Redis primary key')
@secure()
output redisPrimaryKey string = redisCache.listKeys().primaryKey
