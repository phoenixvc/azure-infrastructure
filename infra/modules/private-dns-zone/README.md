# Private DNS Zone Module

Creates a Private DNS Zone with VNet link for private endpoint name resolution.

---

## Usage

```bicep
module privateDnsZone '../private-dns-zone/main.bicep' = {
  name: 'postgres-dns-zone'
  params: {
    zoneName: 'privatelink.postgres.database.azure.com'
    vnetId: vnet.outputs.vnetId
    vnetName: naming.outputs.name_vnet
    tags: rg.tags
  }
}
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `zoneName` | string | - | DNS zone name (e.g., `privatelink.postgres.database.azure.com`) |
| `vnetId` | string | - | Virtual Network resource ID to link |
| `vnetName` | string | - | VNet name for link naming |
| `enableAutoRegistration` | bool | false | Auto-register VM DNS records |
| `tags` | object | {} | Resource tags |

---

## Common Zone Names

| Service | Zone Name |
|---------|-----------|
| PostgreSQL | `privatelink.postgres.database.azure.com` |
| SQL Server | `privatelink.database.windows.net` |
| Storage Blob | `privatelink.blob.core.windows.net` |
| Key Vault | `privatelink.vaultcore.azure.net` |
| Container Registry | `privatelink.azurecr.io` |
| App Service | `privatelink.azurewebsites.net` |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `privateDnsZoneId` | string | Private DNS Zone resource ID |
| `privateDnsZoneName` | string | Private DNS Zone name |
