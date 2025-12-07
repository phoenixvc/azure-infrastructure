// ============================================================================
// Azure API Management Module
// ============================================================================
// Creates an API Management instance for API gateway, developer portal,
// rate limiting, and API versioning
//
// See ADR-006: API Framework Selection

@description('API Management service name')
param apimName string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Publisher email for notifications')
param publisherEmail string

@description('Publisher organization name')
param publisherName string

@description('SKU tier: Consumption, Developer, Basic, Standard, Premium')
@allowed(['Consumption', 'Developer', 'Basic', 'Standard', 'Premium'])
param skuName string = 'Consumption'

@description('SKU capacity (number of units, 0 for Consumption)')
@minValue(0)
@maxValue(12)
param skuCapacity int = 0

@description('Tags to apply to resources')
param tags object = {}

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Application Insights resource ID for API analytics')
param appInsightsId string = ''

@description('Application Insights instrumentation key')
@secure()
param appInsightsKey string = ''

@description('Virtual network type: None, External, Internal')
@allowed(['None', 'External', 'Internal'])
param virtualNetworkType string = 'None'

@description('Subnet ID for VNet integration (required if virtualNetworkType != None)')
param subnetId string = ''

@description('Enable developer portal')
param enableDeveloperPortal bool = true

@description('API definitions to import')
param apis array = []
// Example: [{ name: 'my-api', displayName: 'My API', path: 'myapi', serviceUrl: 'https://backend.com' }]

@description('Products to create')
param products array = []
// Example: [{ name: 'starter', displayName: 'Starter', description: 'Basic access', subscriptionRequired: true, approvalRequired: false, subscriptionsLimit: 1, state: 'published' }]

@description('Named values (configuration properties)')
@secure()
param namedValues array = []
// Example: [{ name: 'backend-key', displayName: 'Backend API Key', value: 'secret', secret: true }]

// Determine actual capacity based on SKU
var actualCapacity = skuName == 'Consumption' ? 0 : (skuCapacity == 0 ? 1 : skuCapacity)

// API Management instance
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: actualCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: virtualNetworkType
    virtualNetworkConfiguration: virtualNetworkType != 'None' && !empty(subnetId) ? {
      subnetResourceId: subnetId
    } : null
    customProperties: skuName != 'Consumption' ? {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'False'
    } : {}
    developerPortalStatus: enableDeveloperPortal ? 'Enabled' : 'Disabled'
  }
}

// Application Insights logger (if configured)
resource appInsightsLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = if (!empty(appInsightsId) && !empty(appInsightsKey)) {
  parent: apim
  name: 'app-insights-logger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsightsId
    credentials: {
      instrumentationKey: appInsightsKey
    }
  }
}

// Diagnostic settings for all APIs
resource apiDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2023-05-01-preview' = if (!empty(appInsightsId) && !empty(appInsightsKey)) {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: appInsightsLogger.id
    alwaysLog: 'allErrors'
    logClientIp: true
    httpCorrelationProtocol: 'W3C'
    verbosity: 'information'
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
    frontend: {
      request: {
        headers: ['X-Forwarded-For', 'X-Request-ID']
        body: {
          bytes: 1024
        }
      }
      response: {
        headers: ['X-Request-ID']
        body: {
          bytes: 1024
        }
      }
    }
    backend: {
      request: {
        headers: ['Authorization']
        body: {
          bytes: 1024
        }
      }
      response: {
        body: {
          bytes: 1024
        }
      }
    }
  }
}

// Named values (secrets and configuration)
resource namedValueResources 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = [for nv in namedValues: {
  parent: apim
  name: nv.name
  properties: {
    displayName: nv.displayName
    value: nv.value
    secret: contains(nv, 'secret') ? nv.secret : false
  }
}]

// Products
resource productResources 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = [for product in products: {
  parent: apim
  name: product.name
  properties: {
    displayName: product.displayName
    description: contains(product, 'description') ? product.description : ''
    subscriptionRequired: contains(product, 'subscriptionRequired') ? product.subscriptionRequired : true
    approvalRequired: contains(product, 'approvalRequired') ? product.approvalRequired : false
    subscriptionsLimit: contains(product, 'subscriptionsLimit') ? product.subscriptionsLimit : 1
    state: contains(product, 'state') ? product.state : 'published'
  }
}]

// APIs
resource apiResources 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = [for api in apis: {
  parent: apim
  name: api.name
  properties: {
    displayName: api.displayName
    path: api.path
    serviceUrl: api.serviceUrl
    protocols: ['https']
    subscriptionRequired: contains(api, 'subscriptionRequired') ? api.subscriptionRequired : true
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    apiType: 'http'
  }
}]

// Global rate limiting policy
resource globalPolicy 'Microsoft.ApiManagement/service/policies@2023-05-01-preview' = {
  parent: apim
  name: 'policy'
  properties: {
    format: 'xml'
    value: '''
<policies>
  <inbound>
    <cors allow-credentials="true">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods preflight-result-max-age="300">
        <method>*</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
    <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription?.Key ?? context.Request.IpAddress)" />
    <quota-by-key calls="10000" renewal-period="86400" counter-key="@(context.Subscription?.Key ?? context.Request.IpAddress)" />
  </inbound>
  <backend>
    <forward-request />
  </backend>
  <outbound>
    <set-header name="X-Powered-By" exists-action="delete" />
    <set-header name="X-AspNet-Version" exists-action="delete" />
  </outbound>
  <on-error />
</policies>
'''
  }
}

// Diagnostic Settings (Log Analytics)
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId) && skuName != 'Consumption') {
  name: '${apimName}-diagnostics'
  scope: apim
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'WebSocketConnectionLogs'
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
@description('API Management resource ID')
output apimId string = apim.id

@description('API Management name')
output apimName string = apim.name

@description('API Management gateway URL')
output gatewayUrl string = apim.properties.gatewayUrl

@description('Developer portal URL')
output developerPortalUrl string = enableDeveloperPortal ? apim.properties.developerPortalUrl : ''

@description('Management API URL')
output managementApiUrl string = apim.properties.managementApiUrl

@description('API Management principal ID (for RBAC)')
output principalId string = apim.identity.principalId

@description('API Management public IP addresses')
output publicIPAddresses array = apim.properties.publicIPAddresses
