// ============================================================================
// Container Apps Module
// ============================================================================
// Creates a Container Apps Environment and Container App with scaling,
// secrets management, and observability integration
//
// See ADR-009: Container & Compute Strategy

@description('Container App name (from naming module)')
param appName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Container image to deploy')
param containerImage string

@description('Container registry server (e.g., myregistry.azurecr.io)')
param containerRegistryServer string = ''

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Log Analytics Workspace customer ID for environment')
param logAnalyticsCustomerId string

@description('Log Analytics Workspace shared key for environment')
@secure()
param logAnalyticsSharedKey string

@description('Tags to apply to resources')
param tags object = {}

@description('Subnet ID for VNet integration (optional)')
param subnetId string = ''

@description('Enable external ingress')
param enableExternalIngress bool = true

@description('Target port for the container')
param targetPort int = 8000

@description('CPU cores (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0)')
param cpu string = '0.5'

@description('Memory in Gi (0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0)')
param memory string = '1Gi'

@description('Minimum replicas (0 enables scale to zero)')
@minValue(0)
@maxValue(300)
param minReplicas int = 0

@description('Maximum replicas')
@minValue(1)
@maxValue(300)
param maxReplicas int = 10

@description('Enable Dapr sidecar')
param enableDapr bool = false

@description('Dapr app ID (required if enableDapr is true)')
param daprAppId string = ''

@description('Dapr app port')
param daprAppPort int = 8000

@description('Environment variables (array of {name, value} objects)')
param envVars array = []

@description('Secret references (array of {name, value} objects)')
@secure()
param secrets array = []

@description('Key Vault secret references (array of {name, keyVaultUrl, identity} objects)')
param keyVaultSecrets array = []

@description('User-assigned managed identity ID for ACR and Key Vault access')
param userAssignedIdentityId string = ''

// Container Apps Environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${appName}-env'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    vnetConfiguration: !empty(subnetId) ? {
      infrastructureSubnetId: subnetId
      internal: !enableExternalIngress
    } : null
    zoneRedundant: false
  }
}

// Prepare secrets array combining direct secrets and Key Vault references
var allSecrets = concat(
  [for secret in secrets: {
    name: secret.name
    value: secret.value
  }],
  [for kvSecret in keyVaultSecrets: {
    name: kvSecret.name
    keyVaultUrl: kvSecret.keyVaultUrl
    identity: kvSecret.identity
  }]
)

// Prepare environment variables with secret references
var secretEnvVars = [for secret in secrets: {
  name: toUpper(replace(secret.name, '-', '_'))
  secretRef: secret.name
}]

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: appName
  location: location
  tags: tags
  identity: !empty(userAssignedIdentityId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: enableExternalIngress
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: !empty(containerRegistryServer) ? [
        {
          server: containerRegistryServer
          identity: !empty(userAssignedIdentityId) ? userAssignedIdentityId : 'system'
        }
      ] : []
      secrets: !empty(allSecrets) ? allSecrets : []
      dapr: enableDapr ? {
        enabled: true
        appId: daprAppId
        appPort: daprAppPort
        appProtocol: 'http'
      } : null
    }
    template: {
      containers: [
        {
          name: appName
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: concat(envVars, secretEnvVars)
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: targetPort
              }
              initialDelaySeconds: 10
              periodSeconds: 30
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: targetPort
              }
              initialDelaySeconds: 5
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

// Diagnostic Settings for Environment
resource envDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appName}-env-diagnostics'
  scope: containerAppsEnvironment
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
      }
      {
        category: 'ContainerAppSystemLogs'
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
output environmentId string = containerAppsEnvironment.id
output environmentName string = containerAppsEnvironment.name
output containerAppId string = containerApp.id
output containerAppName string = containerApp.name
output containerAppUrl string = enableExternalIngress ? 'https://${containerApp.properties.configuration.ingress.fqdn}' : ''
output principalId string = !empty(userAssignedIdentityId) ? '' : containerApp.identity.principalId
