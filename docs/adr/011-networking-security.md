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

## Cost Estimation

### Networking Component Costs

| Component | Pricing | Monthly Estimate |
|-----------|---------|------------------|
| VNet | Free | $0 |
| Private Endpoints | ~$7.30/endpoint | ~$50 (7 endpoints) |
| NAT Gateway | ~$32/mo + data | ~$50 |
| Application Gateway | ~$200/mo (WAF v2) | ~$200 |
| Front Door | ~$35/mo + requests | ~$100 |
| DDoS Protection | ~$3,000/mo (Standard) | $3,000 |

### Cost by Environment

| Environment | Components | Monthly Cost |
|-------------|------------|--------------|
| Dev | VNet, 3 PEs | ~$25 |
| Staging | VNet, 5 PEs, AppGW | ~$250 |
| Production | VNet, 7 PEs, AppGW, Front Door | ~$400 |
| Prod + DDoS | Full stack with DDoS Standard | ~$3,500 |

### Cost Optimization

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| DDoS Basic (free) | $3,000/mo | Limited protection |
| Shared Front Door | 50% | Multi-tenant |
| Fewer private endpoints | $7/endpoint | Some public access |
| Standard tier (not Premium) | 20-30% | Reduced features |

## Multi-Cloud Alternatives

### Networking Service Mapping

| Azure | AWS | GCP | Self-Hosted |
|-------|-----|-----|-------------|
| VNet | VPC | VPC | OVS/OVN |
| NSG | Security Groups | Firewall rules | iptables |
| Private Endpoints | PrivateLink | Private Service Connect | - |
| Application Gateway | ALB | Cloud Load Balancer | HAProxy |
| Front Door | CloudFront | Cloud CDN | Cloudflare |
| Azure Firewall | Network Firewall | Cloud Firewall | pfSense |
| DDoS Protection | Shield | Cloud Armor | Cloudflare |
| Private DNS | Route 53 Private | Cloud DNS Private | CoreDNS |

### Security Service Mapping

| Azure | AWS | GCP |
|-------|-----|-----|
| Defender for Cloud | Security Hub | Security Command Center |
| Sentinel | Security Lake + SIEM | Chronicle |
| Key Vault | Secrets Manager | Secret Manager |
| Entra ID | IAM + Cognito | Cloud Identity |

### Zero Trust Platforms

| Platform | Strength | Integration |
|----------|----------|-------------|
| Azure (Entra ID + Conditional Access) | Microsoft ecosystem | Native |
| Google BeyondCorp | Chrome Enterprise | GCP |
| Zscaler | Cloud security | Any |
| Cloudflare Access | Edge security | Any |
| Tailscale | Simple VPN alternative | Any |

## Compliance Frameworks

### Framework Requirements

| Framework | Network Requirements | Azure Implementation |
|-----------|---------------------|---------------------|
| SOC 2 | Access controls, logging | NSG, Flow Logs, Defender |
| HIPAA | Encryption, segmentation | Private Endpoints, TLS |
| PCI DSS | Network segmentation | Subnet isolation, WAF |
| ISO 27001 | Defense in depth | Full stack |
| FedRAMP | Government controls | Azure Government |

### Compliance Monitoring

| Control | Azure Service | Evidence |
|---------|---------------|----------|
| Network segmentation | Azure Policy | NSG configurations |
| Encryption in transit | TLS 1.2+ | Certificate inventory |
| Access logging | Activity Log | Audit exports |
| Threat detection | Defender | Alert reports |

## Disaster Recovery

### Network DR Configuration

| Component | Primary | DR Site |
|-----------|---------|---------|
| VNet | East US | West US |
| Peering | Hub-spoke | Hub-spoke |
| DNS | Azure DNS | Azure DNS (global) |
| Front Door | Active | Active (global) |
| ExpressRoute | Primary circuit | Backup circuit |

### Failover Procedures

| Step | Action | Automation |
|------|--------|------------|
| 1 | Detect outage | Azure Monitor |
| 2 | DNS failover | Traffic Manager |
| 3 | Database failover | Geo-replication |
| 4 | Validate connectivity | Health probes |
| 5 | Update configurations | Azure Automation |

### Network Resilience Patterns

| Pattern | Implementation | Use Case |
|---------|----------------|----------|
| Active-Passive | Traffic Manager priority | Cost-conscious |
| Active-Active | Traffic Manager weighted | High availability |
| Multi-region load balancing | Front Door | Global reach |
| ExpressRoute redundancy | Dual circuits | Hybrid cloud |

## Advanced Security Patterns

### Micro-segmentation

| Pattern | Implementation | Benefit |
|---------|----------------|---------|
| App-level isolation | ASG (Application Security Groups) | Granular control |
| Workload isolation | Dedicated subnets | Blast radius |
| Service mesh | Dapr with mTLS | Zero-trust networking |

### Threat Protection

| Threat | Detection | Prevention |
|--------|-----------|------------|
| DDoS | Azure DDoS Protection | Rate limiting |
| SQL Injection | WAF rules | Input validation |
| XSS | WAF rules | Output encoding |
| Data exfiltration | Defender | Egress filtering |
| Credential theft | Entra ID Protection | Conditional Access |

### Network Monitoring

| Metric | Alert Threshold | Action |
|--------|-----------------|--------|
| NSG deny count | > 100/min | Investigate |
| Latency spike | > 500ms | Scale/failover |
| Bandwidth saturation | > 80% | Scale out |
| Failed connections | > 5% | Check health |

## References

- [Azure Private Link](https://docs.microsoft.com/azure/private-link/)
- [Network Security Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices)
- [Zero Trust Architecture](https://docs.microsoft.com/azure/security/fundamentals/zero-trust)
- [Azure Network Pricing](https://azure.microsoft.com/pricing/details/virtual-network/)
- [AWS VPC](https://aws.amazon.com/vpc/)
- [GCP VPC](https://cloud.google.com/vpc)
