// ============================================================================
// Log Analytics Module
// ============================================================================
// Creates a Log Analytics Workspace with Application Insights

@description('Log Analytics Workspace name (from naming module)')
param logAnalyticsName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Log Analytics SKU')
@allowed(['Free', 'PerGB2018', 'PerNode', 'Standalone'])
param sku string = 'PerGB2018'

@description('Retention in days (30-730)')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Daily ingestion cap in GB (-1 for no cap)')
param dailyQuotaGb int = -1

@description('Enable Application Insights')
param enableApplicationInsights bool = true

@description('Application Insights name')
param appInsightsName string = ''

@description('Tags to apply to resources')
param tags object = {}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    workspaceCapping: dailyQuotaGb > 0 ? {
      dailyQuotaGb: dailyQuotaGb
    } : null
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: appInsightsName != '' ? appInsightsName : '${logAnalyticsName}-ai'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    RetentionInDays: retentionInDays
  }
}

// Common Log Analytics Solutions
resource containerInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${logAnalyticsName})'
  location: location
  tags: tags
  plan: {
    name: 'ContainerInsights(${logAnalyticsName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/ContainerInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalytics.id
  }
}

// Alert Rule: High Error Rate
resource highErrorRateAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = if (enableApplicationInsights) {
  name: '${logAnalyticsName}-high-error-rate'
  location: location
  tags: tags
  properties: {
    displayName: 'High Error Rate Alert'
    description: 'Triggers when error rate exceeds threshold'
    enabled: true
    scopes: [
      enableApplicationInsights ? appInsights.id : logAnalytics.id
    ]
    severity: 2
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'requests | where success == false | summarize errorCount = count() by bin(timestamp, 5m) | where errorCount > 10'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
  }
}

// Outputs
output logAnalyticsId string = logAnalytics.id
output logAnalyticsName string = logAnalytics.name
output logAnalyticsWorkspaceId string = logAnalytics.properties.customerId
output appInsightsId string = enableApplicationInsights ? appInsights.id : ''
output appInsightsName string = enableApplicationInsights ? appInsights.name : ''
output appInsightsInstrumentationKey string = enableApplicationInsights ? appInsights.properties.InstrumentationKey : ''
output appInsightsConnectionString string = enableApplicationInsights ? appInsights.properties.ConnectionString : ''
