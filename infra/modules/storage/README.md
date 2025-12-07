# Storage Account Module

Creates a Storage Account with:
- ✅ Blob containers
- ✅ HTTPS only
- ✅ Private access (no public blobs)
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

module storage '../storage/main.bicep' = {
name: 'storage'
params: {
  storageName: naming.outputs.name_storage
  location: 'westeurope'
  sku: 'Standard_LRS'
  containerNames: ['uploads', 'processed', 'archive']
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
| `storageName` | string | - | Storage Account name |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'Standard_LRS' | Storage Account SKU |
| `containerNames` | array | [] | Blob container names to create |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `storageAccountId` | string | Storage Account resource ID |
| `storageAccountName` | string | Storage Account name |
| `primaryEndpoints` | object | Primary endpoints (blob, file, queue, table) |
