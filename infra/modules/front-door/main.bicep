// ============================================================================
// Azure Front Door Module
// ============================================================================
// Creates an Azure Front Door Standard/Premium for global load balancing,
// CDN, WAF, and edge optimization
//
// See ADR-011: Networking & Security

@description('Front Door profile name')
param profileName string

@description('SKU tier: Standard_AzureFrontDoor or Premium_AzureFrontDoor')
@allowed(['Standard_AzureFrontDoor', 'Premium_AzureFrontDoor'])
param skuName string = 'Standard_AzureFrontDoor'

@description('Tags to apply to resources')
param tags object = {}

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Origin groups configuration')
param originGroups array = []
// Example: [{
//   name: 'default-origin-group',
//   loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3 },
//   healthProbeSettings: { probePath: '/health', probeProtocol: 'Https', probeIntervalInSeconds: 30 },
//   origins: [{ name: 'primary', hostName: 'app.azurewebsites.net', priority: 1, weight: 1000 }]
// }]

@description('Custom domains configuration')
param customDomains array = []
// Example: [{ name: 'contoso-com', hostName: 'www.contoso.com' }]

@description('Routes configuration')
param routes array = []
// Example: [{ name: 'default-route', originGroupName: 'default-origin-group', patternsToMatch: ['/*'], supportedProtocols: ['Https'], forwardingProtocol: 'HttpsOnly' }]

@description('Enable WAF (requires Premium SKU)')
param enableWaf bool = false

@description('WAF mode: Detection or Prevention')
@allowed(['Detection', 'Prevention'])
param wafMode string = 'Prevention'

@description('Enable caching')
param enableCaching bool = true

@description('Cache duration in seconds (default 24 hours)')
param cacheDuration int = 86400

// Front Door Profile
resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: profileName
  location: 'global'
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

// Origin Groups
resource frontDoorOriginGroups 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = [for og in originGroups: {
  parent: frontDoorProfile
  name: og.name
  properties: {
    loadBalancingSettings: {
      sampleSize: contains(og, 'loadBalancingSettings') ? og.loadBalancingSettings.sampleSize : 4
      successfulSamplesRequired: contains(og, 'loadBalancingSettings') ? og.loadBalancingSettings.successfulSamplesRequired : 3
      additionalLatencyInMilliseconds: contains(og, 'loadBalancingSettings') ? og.loadBalancingSettings.additionalLatencyInMilliseconds : 50
    }
    healthProbeSettings: contains(og, 'healthProbeSettings') ? {
      probePath: og.healthProbeSettings.probePath
      probeProtocol: og.healthProbeSettings.probeProtocol
      probeIntervalInSeconds: og.healthProbeSettings.probeIntervalInSeconds
      probeRequestType: contains(og.healthProbeSettings, 'probeRequestType') ? og.healthProbeSettings.probeRequestType : 'HEAD'
    } : null
    sessionAffinityState: contains(og, 'sessionAffinity') && og.sessionAffinity ? 'Enabled' : 'Disabled'
  }
}]

// Origins
resource frontDoorOrigins 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = [for item in flatten([for (og, i) in originGroups: [for origin in og.origins: {
  originGroupIndex: i
  originGroupName: og.name
  name: origin.name
  hostName: origin.hostName
  priority: contains(origin, 'priority') ? origin.priority : 1
  weight: contains(origin, 'weight') ? origin.weight : 1000
  httpPort: contains(origin, 'httpPort') ? origin.httpPort : 80
  httpsPort: contains(origin, 'httpsPort') ? origin.httpsPort : 443
  originHostHeader: contains(origin, 'originHostHeader') ? origin.originHostHeader : origin.hostName
  enabledState: contains(origin, 'enabled') && !origin.enabled ? 'Disabled' : 'Enabled'
}]]): {
  parent: frontDoorOriginGroups[item.originGroupIndex]
  name: item.name
  properties: {
    hostName: item.hostName
    httpPort: item.httpPort
    httpsPort: item.httpsPort
    originHostHeader: item.originHostHeader
    priority: item.priority
    weight: item.weight
    enabledState: item.enabledState
    enforceCertificateNameCheck: true
  }
}]

// Custom Domains
resource frontDoorCustomDomains 'Microsoft.Cdn/profiles/customDomains@2023-05-01' = [for domain in customDomains: {
  parent: frontDoorProfile
  name: domain.name
  properties: {
    hostName: domain.hostName
    tlsSettings: {
      certificateType: contains(domain, 'certificateType') ? domain.certificateType : 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}]

// Endpoint
resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: '${profileName}-endpoint'
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

// Routes
resource frontDoorRoutes 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = [for (route, i) in routes: {
  parent: frontDoorEndpoint
  name: route.name
  properties: {
    originGroup: {
      id: resourceId('Microsoft.Cdn/profiles/originGroups', profileName, route.originGroupName)
    }
    customDomains: contains(route, 'customDomains') ? [for domain in route.customDomains: {
      id: resourceId('Microsoft.Cdn/profiles/customDomains', profileName, domain)
    }] : []
    patternsToMatch: route.patternsToMatch
    supportedProtocols: contains(route, 'supportedProtocols') ? route.supportedProtocols : ['Https']
    forwardingProtocol: contains(route, 'forwardingProtocol') ? route.forwardingProtocol : 'HttpsOnly'
    httpsRedirect: contains(route, 'httpsRedirect') ? route.httpsRedirect : 'Enabled'
    linkToDefaultDomain: contains(route, 'linkToDefaultDomain') ? route.linkToDefaultDomain : 'Enabled'
    cacheConfiguration: enableCaching ? {
      queryStringCachingBehavior: 'UseQueryString'
      compressionSettings: {
        isCompressionEnabled: true
        contentTypesToCompress: [
          'text/html'
          'text/css'
          'text/javascript'
          'application/javascript'
          'application/json'
          'application/xml'
          'image/svg+xml'
        ]
      }
    } : null
  }
  dependsOn: [
    frontDoorOriginGroups
    frontDoorOrigins
    frontDoorCustomDomains
  ]
}]

// WAF Policy (Premium only)
resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = if (enableWaf && skuName == 'Premium_AzureFrontDoor') {
  name: '${profileName}WafPolicy'
  location: 'global'
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: wafMode
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleSetAction: 'Block'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
    customRules: {
      rules: [
        {
          name: 'RateLimitRule'
          enabledState: 'Enabled'
          priority: 100
          ruleType: 'RateLimitRule'
          rateLimitThreshold: 1000
          rateLimitDurationInMinutes: 1
          action: 'Block'
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Any'
              negateCondition: false
              matchValue: []
            }
          ]
        }
      ]
    }
  }
}

// Security Policy (links WAF to endpoint)
resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = if (enableWaf && skuName == 'Premium_AzureFrontDoor') {
  parent: frontDoorProfile
  name: '${profileName}-security-policy'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: frontDoorEndpoint.id
            }
          ]
          patternsToMatch: ['/*']
        }
      ]
    }
  }
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${profileName}-diagnostics'
  scope: frontDoorProfile
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'FrontDoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontDoorHealthProbeLog'
        enabled: true
      }
      {
        category: 'FrontDoorWebApplicationFirewallLog'
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
@description('Front Door profile resource ID')
output profileId string = frontDoorProfile.id

@description('Front Door profile name')
output profileName string = frontDoorProfile.name

@description('Front Door endpoint hostname')
output endpointHostName string = frontDoorEndpoint.properties.hostName

@description('Front Door endpoint URL')
output endpointUrl string = 'https://${frontDoorEndpoint.properties.hostName}'

@description('Front Door endpoint ID')
output endpointId string = frontDoorEndpoint.id

@description('WAF policy ID (if enabled)')
output wafPolicyId string = enableWaf && skuName == 'Premium_AzureFrontDoor' ? wafPolicy.id : ''
