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

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| Azure Front Door | Global load balancing, CDN | Premium SKU for WAF |
| WAF Policy | Attack protection | Prevention mode, OWASP rules |
| Bot Manager | Bot mitigation | Microsoft rule set |

### Layer 2: Network Segmentation

| Subnet | Purpose | NSG Rules |
|--------|---------|-----------|
| App Subnet | Container Apps, App Service | Allow 443 inbound, deny all else |
| Data Subnet | PostgreSQL (delegated) | Allow 5432 from App subnet only |
| Private Endpoints | PaaS services | Allow from VNet only |

### Layer 3: Private Endpoints

| Service | Private DNS Zone |
|---------|------------------|
| Key Vault | `privatelink.vaultcore.azure.net` |
| Storage | `privatelink.blob.core.windows.net` |
| ACR | `privatelink.azurecr.io` |
| PostgreSQL | `privatelink.postgres.database.azure.com` |
| Service Bus | `privatelink.servicebus.windows.net` |

### Layer 4: Identity & Access

| Component | Purpose |
|-----------|---------|
| User-assigned Managed Identity | Service authentication |
| RBAC | Role-based access control |
| Key Vault Access Policies | Secret/key permissions |
| Conditional Access | Risk-based authentication |

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

| Monitoring Type | Service | Purpose |
|-----------------|---------|---------|
| NSG Flow Logs | Network Watcher | Traffic analysis |
| Traffic Analytics | Log Analytics | Pattern detection |
| DDoS Protection | Azure DDoS | Attack mitigation |
| Security Center | Defender for Cloud | Threat detection |

See `infra/modules/vnet/` for the VNet and NSG implementation.

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
