// ============================================================================
// Azure Notification Hubs Module
// ============================================================================
// Creates a Notification Hub for cross-platform push notifications
// Supports iOS (APNs), Android (FCM), Windows (WNS), and more
//
// See ADR-015: Mobile Development

@description('Notification Hub namespace name')
param namespaceName string

@description('Notification Hub name')
param hubName string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('SKU tier: Free, Basic, or Standard')
@allowed(['Free', 'Basic', 'Standard'])
param skuName string = 'Free'

@description('Tags to apply to resources')
param tags object = {}

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

// Platform credentials (all optional - configure as needed)
@description('Apple Push Notification Service (APNs) credentials')
@secure()
param apnsCredential object = {}
// Example: { appId: '', appName: '', endpoint: 'Production', keyId: '', token: '' }

@description('Firebase Cloud Messaging (FCM) V1 credentials')
@secure()
param fcmV1Credential object = {}
// Example: { clientEmail: '', privateKey: '', projectId: '' }

@description('Windows Notification Service (WNS) credentials')
@secure()
param wnsCredential object = {}
// Example: { packageSid: '', secretKey: '' }

@description('Browser Push (Web Push) credentials')
@secure()
param browserCredential object = {}
// Example: { vapidPrivateKey: '', vapidPublicKey: '', subject: '' }

// Notification Hub Namespace
resource notificationHubNamespace 'Microsoft.NotificationHubs/namespaces@2023-09-01' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    zoneRedundancy: skuName == 'Standard' ? 'Enabled' : 'Disabled'
    publicNetworkAccess: 'Enabled'
  }
}

// Notification Hub
resource notificationHub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2023-09-01' = {
  parent: notificationHubNamespace
  name: hubName
  location: location
  tags: tags
  properties: {
    // APNs (iOS) configuration
    apnsCredential: !empty(apnsCredential) ? {
      properties: {
        appId: apnsCredential.appId
        appName: apnsCredential.appName
        endpoint: apnsCredential.endpoint
        keyId: apnsCredential.keyId
        token: apnsCredential.token
      }
    } : null

    // FCM V1 (Android) configuration
    fcmV1Credential: !empty(fcmV1Credential) ? {
      properties: {
        clientEmail: fcmV1Credential.clientEmail
        privateKey: fcmV1Credential.privateKey
        projectId: fcmV1Credential.projectId
      }
    } : null

    // WNS (Windows) configuration
    wnsCredential: !empty(wnsCredential) ? {
      properties: {
        packageSid: wnsCredential.packageSid
        secretKey: wnsCredential.secretKey
        windowsLiveEndpoint: 'https://login.live.com/accesstoken.srf'
      }
    } : null

    // Browser Push (Web) configuration
    browserCredential: !empty(browserCredential) ? {
      properties: {
        vapidPrivateKey: browserCredential.vapidPrivateKey
        vapidPublicKey: browserCredential.vapidPublicKey
        subject: browserCredential.subject
      }
    } : null
  }
}

// Authorization rules for applications
resource listenRule 'Microsoft.NotificationHubs/namespaces/notificationHubs/AuthorizationRules@2023-09-01' = {
  parent: notificationHub
  name: 'ListenAccess'
  properties: {
    rights: ['Listen']
  }
}

resource sendRule 'Microsoft.NotificationHubs/namespaces/notificationHubs/AuthorizationRules@2023-09-01' = {
  parent: notificationHub
  name: 'SendAccess'
  properties: {
    rights: ['Send']
  }
}

resource manageRule 'Microsoft.NotificationHubs/namespaces/notificationHubs/AuthorizationRules@2023-09-01' = {
  parent: notificationHub
  name: 'ManageAccess'
  properties: {
    rights: ['Listen', 'Send', 'Manage']
  }
}

// Diagnostic Settings (if Log Analytics provided)
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${namespaceName}-diagnostics'
  scope: notificationHubNamespace
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'OperationalLogs'
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
@description('Notification Hub namespace resource ID')
output namespaceId string = notificationHubNamespace.id

@description('Notification Hub namespace name')
output namespaceName string = notificationHubNamespace.name

@description('Notification Hub resource ID')
output hubId string = notificationHub.id

@description('Notification Hub name')
output hubName string = notificationHub.name

@description('Listen connection string (for client apps)')
@secure()
output listenConnectionString string = listenRule.listKeys().primaryConnectionString

@description('Send connection string (for backend services)')
@secure()
output sendConnectionString string = sendRule.listKeys().primaryConnectionString

@description('Manage connection string (for admin operations)')
@secure()
output manageConnectionString string = manageRule.listKeys().primaryConnectionString
