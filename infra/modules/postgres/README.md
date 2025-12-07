# PostgreSQL Flexible Server Module

Creates a PostgreSQL Flexible Server with:
- ✅ Configurable version (13-16)
- ✅ Automated backups (7-day retention)
- ✅ Firewall rules
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

module postgres '../postgres/main.bicep' = {
name: 'postgres'
params: {
  dbName: naming.outputs.name_db
  location: 'westeurope'
  postgresVersion: '16'
  skuName: 'Standard_B1ms'
  storageSizeGB: 32
  administratorLogin: 'dbadmin'
  administratorPassword: keyVault.getSecret('db-admin-password')
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
| `dbName` | string | - | PostgreSQL server name |
| `location` | string | resourceGroup().location | Azure region |
| `postgresVersion` | string | '16' | PostgreSQL version |
| `skuName` | string | 'Standard_B1ms' | SKU name |
| `storageSizeGB` | int | 32 | Storage size in GB |
| `administratorLogin` | string (secure) | - | Admin username |
| `administratorPassword` | string (secure) | - | Admin password |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `postgresServerId` | string | PostgreSQL server resource ID |
| `postgresServerName` | string | PostgreSQL server name |
| `postgresServerFqdn` | string | PostgreSQL server FQDN |
