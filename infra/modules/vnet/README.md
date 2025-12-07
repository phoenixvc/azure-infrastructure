# Virtual Network Module

Creates an Azure Virtual Network with:
- ✅ Configurable address space
- ✅ Multiple subnets (default, app-service, database, private-endpoints)
- ✅ Network Security Groups per subnet
- ✅ Service endpoints
- ✅ Subnet delegations
- ✅ DDoS protection (optional)
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

module vnet '../vnet/main.bicep' = {
  name: 'vnet'
  params: {
    vnetName: naming.outputs.name_vnet
    location: 'westeurope'
    addressPrefix: '10.0.0.0/16'
    enableDdosProtection: false
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
| `vnetName` | string | - | Virtual Network name (from naming module) |
| `location` | string | resourceGroup().location | Azure region |
| `addressPrefix` | string | '10.0.0.0/16' | VNet address space |
| `subnets` | array | (see below) | Subnet configurations |
| `enableDdosProtection` | bool | false | Enable DDoS protection |
| `logAnalyticsWorkspaceId` | string | - | Log Analytics workspace ID |
| `tags` | object | {} | Resource tags |

---

## Default Subnets

| Subnet | Address | Purpose |
|--------|---------|---------|
| `default` | 10.0.1.0/24 | General purpose workloads |
| `app-service` | 10.0.2.0/24 | App Service VNet integration |
| `database` | 10.0.3.0/24 | PostgreSQL Flexible Server |
| `private-endpoints` | 10.0.4.0/24 | Private endpoints for PaaS services |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vnetId` | string | Virtual Network resource ID |
| `vnetName` | string | Virtual Network name |
| `subnetIds` | object | Subnet resource IDs (default, appService, database, privateEndpoints) |
| `addressPrefix` | string | VNet address space |

---

## Network Security

Each subnet has a dedicated NSG with appropriate rules:

- **Default**: Allows HTTP/HTTPS inbound, denies all other
- **Database**: Allows PostgreSQL (5432) from VNet only
- **Private Endpoints**: Allows all VNet traffic, denies external
