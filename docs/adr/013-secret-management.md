# ADR-013: Secret Management Strategy

## Status

Accepted

## Date

2025-12-07

## Context

The platform handles sensitive data including:
- Database connection strings
- API keys and tokens
- TLS certificates
- Encryption keys
- Service credentials

We need a secret management strategy that ensures security, enables rotation, and provides audit capabilities.

## Decision Drivers

- **Security**: Encryption, access control, audit
- **Azure Integration**: Native service support
- **Rotation**: Automated credential rotation
- **Developer Experience**: Easy local development
- **Compliance**: SOC2, HIPAA, PCI requirements

## Considered Options

1. **Azure Key Vault**
2. **HashiCorp Vault**
3. **AWS Secrets Manager**
4. **Environment Variables (CI/CD)**
5. **Azure App Configuration**

## Evaluation Matrix

| Criterion | Weight | Key Vault | HashiCorp Vault | AWS Secrets | Env Vars | App Config |
|-----------|--------|-----------|-----------------|-------------|----------|------------|
| Azure Integration | 5 | 5 (25) | 3 (15) | 2 (10) | 4 (20) | 5 (25) |
| Managed Service | 4 | 5 (20) | 2 (8) | 5 (20) | 5 (20) | 5 (20) |
| Secret Rotation | 5 | 4 (20) | 5 (25) | 4 (20) | 1 (5) | 2 (10) |
| HSM Support | 4 | 5 (20) | 4 (16) | 4 (16) | 1 (4) | 1 (4) |
| Certificate Mgmt | 4 | 5 (20) | 4 (16) | 3 (12) | 1 (4) | 1 (4) |
| Access Audit | 5 | 5 (25) | 5 (25) | 5 (25) | 2 (10) | 4 (20) |
| Cost | 3 | 4 (12) | 2 (6) | 4 (12) | 5 (15) | 4 (12) |
| Local Dev | 3 | 4 (12) | 4 (12) | 3 (9) | 5 (15) | 4 (12) |
| **Total** | **33** | **154** | **123** | **124** | **93** | **107** |

## Decision

**Azure Key Vault** as the primary secret store with:

| Secret Type | Storage | Access Pattern |
|-------------|---------|----------------|
| Connection strings | Key Vault Secrets | Key Vault reference |
| API keys | Key Vault Secrets | Managed Identity |
| TLS certificates | Key Vault Certificates | Auto-renewal |
| Encryption keys | Key Vault Keys | CMK integration |
| Feature flags | App Configuration | Dynamic refresh |

## Rationale

Azure Key Vault selected because:

1. **Native Azure integration**: Key Vault references in App Service, Container Apps, Functions
2. **Managed Identity**: No credentials needed to access secrets
3. **HSM backing**: FIPS 140-2 Level 2 (Standard) or Level 3 (Premium) validation
4. **Certificate lifecycle**: Auto-renewal with Let's Encrypt or DigiCert
5. **Comprehensive audit**: All access logged to Azure Monitor

## Secret Categories

### Application Secrets

| Secret | Rotation | Access |
|--------|----------|--------|
| Database credentials | 90 days | API services |
| Redis connection | 90 days | API services |
| Service Bus connection | Annual | Workers |
| External API keys | Per provider | API services |

### Infrastructure Secrets

| Secret | Rotation | Access |
|--------|----------|--------|
| Storage account keys | 90 days | Backup services |
| Container registry tokens | 30 days | CI/CD |
| SSH keys | Annual | Bastion access |

### Certificates

| Certificate | Type | Renewal |
|-------------|------|---------|
| TLS/SSL | DigiCert or Let's Encrypt | Auto-renew |
| Code signing | DigiCert EV | Annual |
| Client auth | Self-signed | Annual |

## Access Patterns

### Key Vault Reference (Recommended)

Applications retrieve secrets at startup via configuration:
- No code changes needed
- Secrets cached and refreshed
- Works with App Service, Container Apps, Functions

### Managed Identity Direct Access

For dynamic secret access:
- SDK retrieves secrets at runtime
- Enables caching strategies
- Required for custom rotation logic

### Local Development

| Option | Use Case |
|--------|----------|
| Azure CLI auth | Developer with Azure access |
| Service principal | CI/CD, automation |
| Local secrets file | Offline development (gitignored) |

## Rotation Strategy

### Automated Rotation

- Database passwords: Azure Event Grid triggers rotation function
- Storage keys: Built-in Key Vault rotation
- Certificates: Auto-renewal with CA integration

### Manual Rotation (with automation support)

- External API keys: Notification-based workflow
- Legacy credentials: Scheduled rotation jobs

## Security Controls

| Control | Implementation |
|---------|----------------|
| Encryption at rest | Azure-managed or CMK |
| Encryption in transit | TLS 1.2+ enforced |
| Access control | RBAC + Access Policies |
| Network isolation | Private endpoints |
| Soft delete | 90-day retention |
| Purge protection | Enabled for production |

## Disaster Recovery

| Scenario | Recovery |
|----------|----------|
| Accidental deletion | Soft delete recovery |
| Key Vault unavailable | Geo-replica failover |
| Credential compromise | Immediate rotation |
| Complete loss | Backup restore + rotation |

## Consequences

### Positive

- Centralized secret management
- Comprehensive audit logging
- Automatic certificate renewal
- No secrets in code or config files
- HSM protection for keys

### Negative

- Dependency on Key Vault availability
- Additional latency for secret retrieval
- Cost increases with scale
- Learning curve for access patterns

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Key Vault unavailable | Low | High | Geo-replication, caching |
| Unauthorized access | Low | Critical | RBAC, private endpoints, audit |
| Secret sprawl | Medium | Medium | Naming conventions, cleanup automation |
| Rotation failures | Medium | High | Monitoring, alerting, runbooks |

## Compliance Mapping

| Requirement | Key Vault Feature |
|-------------|-------------------|
| SOC2 - Access control | RBAC, audit logs |
| HIPAA - Encryption | HSM, encryption at rest |
| PCI - Key management | HSM, key rotation |
| GDPR - Data protection | Regional deployment, purge |

## References

- Azure Key Vault documentation
- Key Vault best practices
- Managed identity overview
- Certificate management guide
