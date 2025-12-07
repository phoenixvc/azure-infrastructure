# Log Analytics Module

Creates a Log Analytics Workspace with:
- ✅ Configurable retention (30-730 days)
- ✅ Daily ingestion cap
- ✅ Application Insights integration
- ✅ Container Insights solution
- ✅ Pre-configured alert rules
- ✅ RBAC-based access

---

## Usage

```bicep
module naming '../naming/main.bicep' = {
  name: 'naming'
  params: {
    org: 'nl'
    env: 'prod'
    project: 'rooivalk'
    region: 'euw'
  }
}

module logAnalytics '../log-analytics/main.bicep' = {
  name: 'log-analytics'
  params: {
    logAnalyticsName: naming.outputs.name_log
    location: 'westeurope'
    retentionInDays: 90
    enableApplicationInsights: true
    appInsightsName: naming.outputs.name_ai
    tags: {
      org: 'nl'
      env: 'prod'
      project: 'rooivalk'
    }
  }
}
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `logAnalyticsName` | string | - | Workspace name (from naming module) |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'PerGB2018' | Pricing SKU |
| `retentionInDays` | int | 30 | Log retention (30-730 days) |
| `dailyQuotaGb` | int | -1 | Daily cap (-1 = unlimited) |
| `enableApplicationInsights` | bool | true | Create App Insights |
| `appInsightsName` | string | '' | App Insights name |
| `tags` | object | {} | Resource tags |

---

## SKU Options

| SKU | Description | Best For |
|-----|-------------|----------|
| `Free` | 500 MB/day, 7 days retention | Development |
| `PerGB2018` | Pay per GB ingested | Most workloads |
| `PerNode` | Per monitored node | Large-scale monitoring |
| `Standalone` | Legacy pricing | Existing agreements |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `logAnalyticsId` | string | Workspace resource ID |
| `logAnalyticsName` | string | Workspace name |
| `logAnalyticsWorkspaceId` | string | Workspace GUID |
| `appInsightsId` | string | App Insights resource ID |
| `appInsightsName` | string | App Insights name |
| `appInsightsInstrumentationKey` | string | Instrumentation key |
| `appInsightsConnectionString` | string | Connection string |

---

## Built-in Alerts

This module creates the following alerts:

1. **High Error Rate** - Triggers when >10 failed requests in 15 minutes

---

## Query Examples

```kusto
// Request performance
requests
| where timestamp > ago(24h)
| summarize avg(duration), percentile(duration, 95) by bin(timestamp, 1h)

// Error breakdown
requests
| where success == false
| summarize count() by resultCode, operation_Name
| order by count_ desc

// Dependency failures
dependencies
| where success == false
| summarize count() by target, type
```

---

## Application Insights Integration

When `enableApplicationInsights` is true:

```python
# Python FastAPI example
from azure.monitor.opentelemetry import configure_azure_monitor

configure_azure_monitor(
    connection_string="<appInsightsConnectionString>"
)
```

```csharp
// .NET example
builder.Services.AddApplicationInsightsTelemetry(
    builder.Configuration["ApplicationInsights:ConnectionString"]
);
```
