# ADR-011: Networking & Security Architecture

## Status

Accepted

## Date

2025-12-07

## Context

The platform requires a secure networking architecture that:
- Isolates production workloads from the internet
- Provides secure service-to-service communication
- Meets compliance requirements (SOC2, HIPAA, etc.)
- Enables Zero Trust security model
- Supports hybrid cloud scenarios

## Decision Drivers

- **Security**: Defense in depth, least privilege
- **Compliance**: Data residency, audit requirements
- **Performance**: Low latency for internal traffic
- **Cost**: Balance security with operational costs
- **Manageability**: Simplified operations

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Azure Region                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                        Virtual Network                              │ │
│  │                      (10.0.0.0/16)                                  │ │
│  ├────────────────────────────────────────────────────────────────────┤ │
│  │                                                                     │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐ │ │
│  │  │  App Subnet     │  │  Data Subnet    │  │  Private Endpoints  │ │ │
│  │  │  10.0.1.0/24    │  │  10.0.2.0/24    │  │  10.0.3.0/24        │ │ │
│  │  │  ─────────────  │  │  ─────────────  │  │  ─────────────────  │ │ │
│  │  │  • Container    │  │  • PostgreSQL   │  │  • Key Vault        │ │ │
│  │  │    Apps         │  │    (delegated)  │  │  • Storage          │ │ │
│  │  │  • App Service  │  │                 │  │  • ACR              │ │ │
│  │  │                 │  │                 │  │  • Service Bus      │ │ │
│  │  │  NSG: Allow     │  │  NSG: Allow     │  │  NSG: Allow from    │ │ │
│  │  │  443 inbound    │  │  5432 from App  │  │  VNet only          │ │ │
│  │  └────────┬────────┘  └────────┬────────┘  └─────────┬───────────┘ │ │
│  │           │                    │                     │              │ │
│  │  ┌────────┴────────────────────┴─────────────────────┴────────────┐ │ │
│  │  │                    Private DNS Zones                            │ │ │
│  │  │  • privatelink.postgres.database.azure.com                      │ │ │
│  │  │  • privatelink.vaultcore.azure.net                              │ │ │
│  │  │  • privatelink.blob.core.windows.net                            │ │ │
│  │  │  • privatelink.azurecr.io                                       │ │ │
│  │  └─────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                     │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌────────────────────┐                    ┌─────────────────────────┐  │
│  │  Application       │◄───────────────────│   Azure Front Door      │  │
│  │  Gateway + WAF     │                    │   (Global LB + CDN)     │  │
│  │  (Regional)        │                    │                         │  │
│  └────────────────────┘                    └─────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Security Layers

### Layer 1: Edge Protection

```bicep
// Azure Front Door with WAF
resource frontDoor 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorName
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
}

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: 'waf-policy'
  properties: {
    policySettings: {
      mode: 'Prevention'
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}
```

### Layer 2: Network Segmentation

```bicep
// NSG for Application Subnet
resource appNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-app-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}
```

### Layer 3: Private Endpoints

```bicep
// Private Endpoint for Key Vault
resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${keyVaultName}-pe'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'keyVaultConnection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: ['vault']
        }
      }
    ]
  }
}

// Private DNS Zone Link
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}
```

### Layer 4: Identity & Access

```bicep
// Managed Identity for services
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${prefix}-identity'
  location: location
}

// Key Vault access policy
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: managedIdentity.properties.principalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}
```

## Zero Trust Implementation

| Principle | Implementation |
|-----------|----------------|
| Verify explicitly | Azure AD + Managed Identity for all access |
| Least privilege | RBAC with minimal permissions |
| Assume breach | Network segmentation, logging, alerts |

### Managed Identity Flow

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ Container   │    │   Azure AD   │    │  Key Vault  │
│ App         │───►│   Token      │───►│  (verify)   │
│             │    │   Request    │    │             │
│ Identity:   │◄───│   Token      │◄───│  Secret     │
│ MSI         │    │   Response   │    │             │
└─────────────┘    └──────────────┘    └─────────────┘
```

## Security Monitoring

```bicep
// Diagnostic settings for NSG flow logs
resource nsgFlowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  name: 'nsg-flow-logs'
  location: location
  properties: {
    targetResourceId: appNsg.id
    storageId: storageAccount.id
    enabled: true
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalytics.id
        trafficAnalyticsInterval: 10
      }
    }
  }
}
```

## Consequences

### Positive

- Defense in depth with multiple security layers
- Private endpoints eliminate public internet exposure
- Managed Identity eliminates credential management
- Comprehensive audit logging

### Negative

- Increased complexity
- Private endpoints add cost
- DNS management complexity
- Debugging network issues harder

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Misconfigured NSG | Medium | High | Use Azure Policy, regular audits |
| DNS resolution failure | Low | High | Test DNS, use health checks |
| Private endpoint quota | Low | Medium | Request quota increase |

## References

- [Azure Private Link](https://docs.microsoft.com/azure/private-link/)
- [Network Security Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices)
- [Zero Trust Architecture](https://docs.microsoft.com/azure/security/fundamentals/zero-trust)
