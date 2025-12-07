# Security Policy

## Reporting a Vulnerability

We take infrastructure security seriously. If you discover a security vulnerability in our infrastructure code, please follow these guidelines:

### Contact

**DO NOT** open a public issue for security vulnerabilities.

**Email**: security@phoenixvc.co.za

### What to Include

1. **Description** - Clear description of the vulnerability
2. **Impact** - Potential infrastructure impact
3. **Affected Resources** - Which Bicep modules are affected
4. **Steps to Reproduce** - How to identify the issue
5. **Suggested Fix** - Recommended remediation
6. **Your Contact Info** - For follow-up

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution**: Based on severity

---

## Infrastructure Security

### Security Features

#### Network Security

- **Virtual Network Isolation** - Private subnets
- **Network Security Groups** - Traffic filtering
- **Private Endpoints** - Private connectivity
- **Azure Firewall** - Centralized protection
- **DDoS Protection** - Standard tier enabled

#### Identity & Access

- **Managed Identities** - Service authentication
- **RBAC** - Role-based access control
- **Azure AD Integration** - Identity management
- **Key Vault** - Secrets management
- **Conditional Access** - Policy-based access

#### Data Protection

- **Encryption at Rest** - All storage encrypted
- **Encryption in Transit** - TLS 1.2+ enforced
- **Key Management** - Customer-managed keys
- **Backup & Recovery** - Automated backups
- **Geo-Redundancy** - Data replication

#### Monitoring & Compliance

- **Azure Monitor** - Centralized monitoring
- **Log Analytics** - Log aggregation
- **Security Center** - Security posture
- **Azure Policy** - Compliance enforcement
- **Diagnostic Settings** - Audit logging

---

## Secure Configuration

### Bicep Best Practices

#### Secrets Management

```bicep
// BAD - Hardcoded secret
param adminPassword string = 'P@ssw0rd123!'

// GOOD - Secure parameter
@secure()
param adminPassword string

// BETTER - Key Vault reference
param adminPassword string = keyVault.getSecret('admin-password')
```

#### Network Security

```bicep
// GOOD - Restrict public access
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  properties: {
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}
```

#### Encryption

```bicep
// GOOD - Enable encryption
resource database 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  properties: {
    storage: {
      storageSizeGB: 128
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Enabled'
    }
    highAvailability: {
      mode: 'ZoneRedundant'
    }
  }
}
```

---

## Security Checklist

### Pre-Deployment

- [ ] No hardcoded secrets
- [ ] Secure parameters used
- [ ] Network isolation configured
- [ ] Encryption enabled
- [ ] Managed identities configured
- [ ] Diagnostic logging enabled
- [ ] Azure Policy compliance
- [ ] Security review completed

### Post-Deployment

- [ ] Verify network rules
- [ ] Check firewall settings
- [ ] Review access policies
- [ ] Validate encryption
- [ ] Test managed identities
- [ ] Monitor security alerts
- [ ] Audit compliance

---

## Security Scanning

### Automated Scans

```bash
# Bicep linting
az bicep lint --file main.bicep

# Security scan with Checkov
checkov -f main.bicep

# Azure Policy compliance
az policy state list --resource-group <rg-name>
```

---

## Security Resources

### Azure Security

- [Azure Security Benchmark](https://docs.microsoft.com/en-us/security/benchmark/azure/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [Azure Well-Architected Framework - Security](https://docs.microsoft.com/en-us/azure/architecture/framework/security/)

### Infrastructure as Code

- [Bicep Security](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/security)
- [Terraform Azure Security](https://www.terraform.io/docs/cloud/guides/recommended-practices/part3.html)

---

## Contact

- **Security Issues**: security@phoenixvc.co.za
- **General Support**: support@phoenixvc.co.za

---

<div align="center">

**Built with love by [Phoenix Venture Capital](https://phoenixvc.co.za)**

*Secure infrastructure by design*

</div>
