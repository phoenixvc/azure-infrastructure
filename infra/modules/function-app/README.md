# Function App Module

Creates an Azure Function App with:
- ✅ Storage Account
- ✅ App Service Plan (Consumption or Premium)
- ✅ Managed Identity
- ✅ HTTPS only
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

module functionApp '../function-app/main.bicep' = {
name: 'function-app'
params: {
  funcName: naming.outputs.name_func
  storageName: naming.outputs.name_storage
  location: 'westeurope'
  sku: 'Y1'
  runtime: 'python'
  runtimeVersion: '3.11'
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
| `funcName` | string | - | Function App name |
| `storageName` | string | - | Storage Account name |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'Y1' | App Service Plan SKU (Y1=Consumption) |
| `runtime` | string | 'python' | Runtime stack |
| `runtimeVersion` | string | '3.11' | Runtime version |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `functionAppId` | string | Function App resource ID |
| `functionAppName` | string | Function App name |
| `functionAppUrl` | string | Function App URL |
| `principalId` | string | Managed Identity principal ID |
| `storageAccountId` | string | Storage Account resource ID |
