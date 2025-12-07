// Azure Service Bus Module
// Provides managed messaging infrastructure for async communication

@description('Service Bus namespace name')
param namespaceName string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('SKU tier: Basic, Standard, or Premium')
@allowed(['Basic', 'Standard', 'Premium'])
param skuName string = 'Standard'

@description('SKU capacity (1-8 for Premium, 0 for Basic/Standard)')
@minValue(0)
@maxValue(8)
param capacity int = 0

@description('Enable zone redundancy (Premium only)')
param zoneRedundant bool = false

@description('Minimum TLS version')
@allowed(['1.0', '1.1', '1.2'])
param minimumTlsVersion string = '1.2'

@description('Tags to apply to resources')
param tags object = {}

@description('Enable public network access')
param publicNetworkAccess string = 'Enabled'

@description('Queue definitions')
param queues array = []
// Example: [{ name: 'orders', maxSizeInMB: 1024, enablePartitioning: false }]

@description('Topic definitions')
param topics array = []
// Example: [{ name: 'events', maxSizeInMB: 1024, subscriptions: ['sub1', 'sub2'] }]

// Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
    capacity: skuName == 'Premium' ? capacity : 0
  }
  properties: {
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    zoneRedundant: skuName == 'Premium' ? zoneRedundant : false
    disableLocalAuth: false
  }
}

// Queues
resource serviceBusQueues 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = [for queue in queues: {
  parent: serviceBusNamespace
  name: queue.name
  properties: {
    maxSizeInMegabytes: contains(queue, 'maxSizeInMB') ? queue.maxSizeInMB : 1024
    enablePartitioning: contains(queue, 'enablePartitioning') ? queue.enablePartitioning : false
    requiresDuplicateDetection: contains(queue, 'requiresDuplicateDetection') ? queue.requiresDuplicateDetection : false
    requiresSession: contains(queue, 'requiresSession') ? queue.requiresSession : false
    deadLetteringOnMessageExpiration: contains(queue, 'enableDeadLettering') ? queue.enableDeadLettering : true
    maxDeliveryCount: contains(queue, 'maxDeliveryCount') ? queue.maxDeliveryCount : 10
    lockDuration: contains(queue, 'lockDuration') ? queue.lockDuration : 'PT1M'
    defaultMessageTimeToLive: contains(queue, 'messageTimeToLive') ? queue.messageTimeToLive : 'P14D'
  }
}]

// Topics (Standard and Premium only)
resource serviceBusTopics 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = [for topic in topics: if (skuName != 'Basic') {
  parent: serviceBusNamespace
  name: topic.name
  properties: {
    maxSizeInMegabytes: contains(topic, 'maxSizeInMB') ? topic.maxSizeInMB : 1024
    enablePartitioning: contains(topic, 'enablePartitioning') ? topic.enablePartitioning : false
    requiresDuplicateDetection: contains(topic, 'requiresDuplicateDetection') ? topic.requiresDuplicateDetection : false
    defaultMessageTimeToLive: contains(topic, 'messageTimeToLive') ? topic.messageTimeToLive : 'P14D'
  }
}]

// Topic Subscriptions
resource serviceBusSubscriptions 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = [for item in flatten([for (topic, i) in topics: [for sub in (contains(topic, 'subscriptions') ? topic.subscriptions : []): {
  topicIndex: i
  topicName: topic.name
  subscriptionName: sub
}]]): if (skuName != 'Basic') {
  parent: serviceBusTopics[item.topicIndex]
  name: item.subscriptionName
  properties: {
    maxDeliveryCount: 10
    lockDuration: 'PT1M'
    deadLetteringOnMessageExpiration: true
  }
}]

// Authorization rule for applications
resource sendListenRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'ApplicationAccess'
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

// Outputs
@description('Service Bus namespace resource ID')
output namespaceId string = serviceBusNamespace.id

@description('Service Bus namespace name')
output namespaceName string = serviceBusNamespace.name

@description('Service Bus namespace endpoint')
output namespaceEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint

@description('Service Bus connection string (Listen/Send)')
@secure()
output connectionString string = sendListenRule.listKeys().primaryConnectionString

@description('Service Bus primary key')
@secure()
output primaryKey string = sendListenRule.listKeys().primaryKey

@description('Queue names')
output queueNames array = [for (queue, i) in queues: serviceBusQueues[i].name]

@description('Topic names')
output topicNames array = skuName != 'Basic' ? [for (topic, i) in topics: serviceBusTopics[i].name] : []
