# App Service Module

Creates an Azure App Service with:
- ✅ App Service Plan
- ✅ Managed Identity
- ✅ HTTPS only
- ✅ Health check endpoint
- ✅ Diagnostic logging

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

module appService '../app-service/main.bicep' = {
name: 'app-service'
params: {
  appName: naming.outputs.name_api
  location: 'westeurope'
  sku: 'B1'
  runtimeStack: 'PYTHON|3.11'
  logAnalyticsWorkspaceId: logAnalytics.id
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
| `appName` | string | - | App Service name (from naming module) |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'B1' | App Service Plan SKU |
| `runtimeStack` | string | 'PYTHON\|3.11' | Runtime stack |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `appServiceId` | string | App Service resource ID |
| `appServiceName` | string | App Service name |
| `appServiceUrl` | string | App Service URL |
| `principalId` | string | Managed Identity principal ID |
