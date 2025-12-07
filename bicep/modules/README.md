# Bicep Modules

## Available Modules

### `naming.bicep`

Generates standardized Azure resource names.

**Usage:**

```bicep
module naming './naming.bicep' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: naming.outputs.rgName
location: 'westeurope'
}
```

**Outputs:**

- `rgName` - Resource group name
- `name_app` - App Service name
- `name_api` - API Service name
- `name_func` - Function App name
- `name_swa` - Static Web App name
- `name_db` - Database name
- `name_storage` - Storage Account name
- `name_kv` - Key Vault name
- `name_queue` - Queue/Service Bus name
- `name_cache` - Redis Cache name
- `name_ai` - AI Service name
- `name_acr` - Container Registry name
- `name_vnet` - Virtual Network name
- `name_subnet` - Subnet name
- `name_dns` - DNS Zone name
- `name_log` - Log Analytics name
