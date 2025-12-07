# Container Registry Module

Creates an Azure Container Registry with:
- ✅ Configurable SKU (Basic, Standard, Premium)
- ✅ Admin user control
- ✅ AcrPull/AcrPush role assignments
- ✅ Retention policies (Premium)
- ✅ Trust policies (Premium)
- ✅ Zone redundancy (Premium)
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

module acr '../container-registry/main.bicep' = {
  name: 'container-registry'
  params: {
    acrName: naming.outputs.name_acr
    location: 'westeurope'
    sku: 'Basic'
    acrPullPrincipalIds: [
      appService.outputs.principalId
    ]
    logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
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
| `acrName` | string | - | ACR name (from naming module) |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'Basic' | ACR SKU (Basic, Standard, Premium) |
| `adminUserEnabled` | bool | false | Enable admin user (not recommended) |
| `publicNetworkAccess` | bool | true | Allow public access |
| `zoneRedundancy` | bool | false | Enable zone redundancy (Premium) |
| `retentionDays` | int | 7 | Retention for untagged manifests (Premium) |
| `acrPullPrincipalIds` | array | [] | Principal IDs for AcrPull role |
| `acrPushPrincipalIds` | array | [] | Principal IDs for AcrPush role |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## SKU Comparison

| Feature | Basic | Standard | Premium |
|---------|-------|----------|---------|
| Storage | 10 GB | 100 GB | 500 GB |
| Webhooks | 2 | 10 | 500 |
| Geo-replication | ❌ | ❌ | ✅ |
| Private endpoints | ❌ | ❌ | ✅ |
| Retention policies | ❌ | ❌ | ✅ |
| Content trust | ❌ | ❌ | ✅ |
| Zone redundancy | ❌ | ❌ | ✅ |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `acrId` | string | Container Registry resource ID |
| `acrName` | string | Container Registry name |
| `acrLoginServer` | string | ACR login server URL |

---

## Docker Usage

```bash
# Login to ACR
az acr login --name nlprodrooivalkacreuew

# Tag and push image
docker tag myapp:latest nlprodrooivalkacreuew.azurecr.io/myapp:latest
docker push nlprodrooivalkacreuew.azurecr.io/myapp:latest
```
