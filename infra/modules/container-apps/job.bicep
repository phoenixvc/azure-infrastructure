// ============================================================================
// Container Apps Job Module
// ============================================================================
// Creates a Container App Job for background processing, scheduled tasks,
// or event-driven execution
//
// See ADR-009: Container & Compute Strategy

@description('Job name (from naming module)')
param jobName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Container Apps Environment ID (from container-apps module)')
param containerAppsEnvironmentId string

@description('Container image to deploy')
param containerImage string

@description('Container registry server (e.g., myregistry.azurecr.io)')
param containerRegistryServer string = ''

@description('Tags to apply to resources')
param tags object = {}

@description('Job trigger type')
@allowed(['Manual', 'Schedule', 'Event'])
param triggerType string = 'Manual'

@description('Cron expression for scheduled jobs (e.g., "0 0 * * *" for daily at midnight)')
param cronExpression string = ''

@description('CPU cores (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0)')
param cpu string = '0.25'

@description('Memory in Gi (0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0)')
param memory string = '0.5Gi'

@description('Number of parallel replicas for the job')
param parallelism int = 1

@description('Number of times to retry failed job executions')
param replicaRetryLimit int = 1

@description('Timeout in seconds for job execution')
param replicaTimeout int = 1800

@description('Environment variables (array of {name, value} objects)')
param envVars array = []

@description('Secret references (array of {name, value} objects)')
@secure()
param secrets array = []

@description('User-assigned managed identity ID for ACR access')
param userAssignedIdentityId string = ''

@description('Service Bus queue name for event-triggered jobs')
param serviceBusQueueName string = ''

@description('Service Bus connection string for event-triggered jobs')
@secure()
param serviceBusConnectionString string = ''

// Prepare secrets array
var allSecrets = triggerType == 'Event' && !empty(serviceBusConnectionString) ? concat(
  [for secret in secrets: {
    name: secret.name
    value: secret.value
  }],
  [{
    name: 'servicebus-connection'
    value: serviceBusConnectionString
  }]
) : [for secret in secrets: {
  name: secret.name
  value: secret.value
}]

// Prepare environment variables with secret references
var secretEnvVars = [for secret in secrets: {
  name: toUpper(replace(secret.name, '-', '_'))
  secretRef: secret.name
}]

// Container Apps Job
resource containerAppJob 'Microsoft.App/jobs@2023-05-01' = {
  name: jobName
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
    environmentId: containerAppsEnvironmentId
    configuration: {
      triggerType: triggerType
      scheduleTriggerConfig: triggerType == 'Schedule' ? {
        cronExpression: cronExpression
        parallelism: parallelism
        replicaCompletionCount: parallelism
      } : null
      eventTriggerConfig: triggerType == 'Event' ? {
        parallelism: parallelism
        replicaCompletionCount: parallelism
        scale: {
          minExecutions: 0
          maxExecutions: 10
          pollingInterval: 30
          rules: [
            {
              name: 'servicebus-rule'
              type: 'azure-servicebus'
              metadata: {
                queueName: serviceBusQueueName
                messageCount: '5'
              }
              auth: [
                {
                  secretRef: 'servicebus-connection'
                  triggerParameter: 'connection'
                }
              ]
            }
          ]
        }
      } : null
      manualTriggerConfig: triggerType == 'Manual' ? {
        parallelism: parallelism
        replicaCompletionCount: parallelism
      } : null
      replicaTimeout: replicaTimeout
      replicaRetryLimit: replicaRetryLimit
      registries: !empty(containerRegistryServer) ? [
        {
          server: containerRegistryServer
          identity: !empty(userAssignedIdentityId) ? userAssignedIdentityId : 'system'
        }
      ] : []
      secrets: !empty(allSecrets) ? allSecrets : []
    }
    template: {
      containers: [
        {
          name: jobName
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: concat(envVars, secretEnvVars)
        }
      ]
    }
  }
}

// Outputs
output jobId string = containerAppJob.id
output jobName string = containerAppJob.name
output principalId string = !empty(userAssignedIdentityId) ? '' : containerAppJob.identity.principalId
