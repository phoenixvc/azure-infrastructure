# Key Vault Module

Creates a Key Vault with:
- ✅ Soft delete enabled (90-day retention)
- ✅ Purge protection
- ✅ Access policies for managed identities
- ✅ Audit logging

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

module keyVault '../key-vault/main.bicep' = {
name: 'key-vault'
params: {
  kvName: naming.outputs.name_kv
  location: 'westeurope'
  skuName: 'standard'
  principalIds: [
    appService.outputs.principalId
    functionApp.outputs.principalId
  ]
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
| `kvName` | string | - | Key Vault name |
| `location` | string | resourceGroup().location | Azure region |
| `skuName` | string | 'standard' | SKU (standard or premium) |
| `principalIds` | array | [] | Managed identity principal IDs to grant access |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `keyVaultId` | string | Key Vault resource ID |
| `keyVaultName` | string | Key Vault name |
| `keyVaultUri` | string | Key Vault URI |
