# ADR-010: Storage Strategy

## Status

Accepted

## Date

2025-12-07

## Context

The platform requires various storage capabilities:
- File uploads and media storage
- Static website hosting
- Application state and configuration
- Backup and archival
- Shared storage between services

We need a storage strategy that addresses different access patterns, performance requirements, and cost constraints.

## Decision Drivers

- **Performance**: Throughput and latency requirements
- **Cost**: Storage tiers for different access patterns
- **Durability**: Data protection and redundancy
- **Access Patterns**: Hot, cool, archive data
- **Security**: Encryption, access control

## Considered Options

1. **Azure Blob Storage**
2. **Azure Files**
3. **Azure Data Lake Storage Gen2**
4. **Azure NetApp Files**
5. **Azure Managed Disks**

## Decision

**Tiered Azure Storage approach**:

| Use Case | Storage Type | Access Tier |
|----------|--------------|-------------|
| User uploads | Blob Storage | Hot |
| Static assets (CDN) | Blob Storage | Hot + CDN |
| Logs/Telemetry | Blob Storage | Cool → Archive |
| Shared config | Azure Files | Hot |
| Large datasets | Data Lake Gen2 | Varies |
| Backups | Blob Storage | Cool/Archive |

## Storage Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Storage Account                               │
│                  (Standard/Premium)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Blob Containers                       │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  uploads/          │  Hot tier, versioning enabled       │    │
│  │  static/           │  Hot tier, CDN endpoint             │    │
│  │  logs/             │  Cool tier, lifecycle policy        │    │
│  │  backups/          │  Archive tier, immutable            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    File Shares                           │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  config/           │  SMB/NFS, shared configuration      │    │
│  │  certificates/     │  SMB, TLS certificates              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Queues                                │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  (Use Service Bus for complex scenarios)                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation

### Storage Account Configuration

| Setting | Value | Purpose |
|---------|-------|---------|
| Kind | StorageV2 | Full feature support |
| TLS Version | 1.2+ | Security compliance |
| Public access | Disabled | Prevent data leakage |
| Network ACLs | VNet rules | Restrict access |
| Encryption | Azure-managed or CMK | Data protection |

### Container Configuration

| Container | Access Level | Features |
|-----------|--------------|----------|
| uploads | Private | Versioning enabled |
| static | Private + CDN | CDN endpoint |
| logs | Private | Lifecycle policy |
| backups | Private | Immutable storage |

### Lifecycle Policy Rules

| Rule | Condition | Action |
|------|-----------|--------|
| Tier to Cool | 30 days after modification | Reduce storage cost |
| Tier to Archive | 90 days after modification | Long-term storage |
| Delete | 365 days after modification | Automatic cleanup |

### Abstraction Requirements

Implement a storage abstraction layer to enable:
- Swapping between Azure Blob and local/mock implementations
- Consistent API for upload, download, delete, and listing
- SAS URL generation for secure, time-limited access

See `infra/modules/storage/` for the Bicep implementation.

## Cost Optimization

| Tier | Use Case | Cost (per GB/month) |
|------|----------|---------------------|
| Hot | Frequently accessed | ~$0.018 |
| Cool | Infrequent access (30+ days) | ~$0.010 |
| Archive | Rare access (180+ days) | ~$0.002 |

### Cost Savings Strategies

1. **Lifecycle policies**: Auto-tier data based on age
2. **Reserved capacity**: Commit for 1-3 years for 30-40% savings
3. **Compression**: Compress before upload
4. **Deduplication**: Hash-based dedup for uploads
5. **CDN**: Reduce egress costs for public content

## Consequences

### Positive

- Highly durable (11 9's with GRS)
- Flexible access tiers
- Strong encryption at rest
- Easy integration with Azure services

### Negative

- Egress costs can add up
- Archive tier has retrieval delays
- No native file system semantics (use Azure Files)

## Multi-Cloud Alternatives

### Object Storage Mapping

| Azure | AWS | GCP | Self-Hosted |
|-------|-----|-----|-------------|
| Blob Storage | S3 | Cloud Storage | MinIO |
| Azure Files | EFS | Filestore | NFS |
| Data Lake Gen2 | S3 + Athena | Cloud Storage | Ceph |
| Archive tier | S3 Glacier | Archive class | Tape |
| CDN (Front Door) | CloudFront | Cloud CDN | Cloudflare |

### Storage Class Comparison

| Azure Tier | AWS S3 Class | GCP Class | Use Case |
|------------|--------------|-----------|----------|
| Hot | Standard | Standard | Frequently accessed |
| Cool | Standard-IA | Nearline | Monthly access |
| Cold | Glacier Instant | Coldline | Quarterly access |
| Archive | Glacier Deep | Archive | Yearly access |

### Pricing Comparison (per GB/month)

| Tier | Azure | AWS | GCP |
|------|-------|-----|-----|
| Standard/Hot | $0.018 | $0.023 | $0.020 |
| Cool/Nearline | $0.010 | $0.0125 | $0.010 |
| Archive | $0.002 | $0.004 | $0.004 |
| Egress (per GB) | $0.087 | $0.090 | $0.120 |

### Cloud-Agnostic SDKs

| Language | Multi-Cloud Library | Description |
|----------|---------------------|-------------|
| Python | boto3 + azure-storage | Direct SDKs |
| Python | cloudpathlib | Unified path API |
| Go | gocloud.dev | Portable cloud APIs |
| Java | Apache jclouds | Multi-cloud abstraction |
| Node.js | pkgcloud | Cloud storage abstraction |

## Disaster Recovery

### Redundancy Options

| Option | Durability | Availability | Use Case |
|--------|------------|--------------|----------|
| LRS | 11 9's | 99.9% | Dev/test |
| ZRS | 12 9's | 99.9% | Production |
| GRS | 16 9's | 99.9% (99.99% RA-GRS) | DR required |
| GZRS | 16 9's | 99.99% | Mission-critical |

### Recovery Scenarios

| Scenario | RTO | RPO | Strategy |
|----------|-----|-----|----------|
| Accidental deletion | Minutes | 0 | Soft delete (14-365 days) |
| Container deletion | Days | 0 | Container soft delete |
| Account compromise | Hours | Point-in-time | Point-in-time restore |
| Region outage | Hours | Minutes-hours | GRS failover |
| Ransomware | Days | 0 | Immutable + versioning |

### Backup Strategy

| Data Type | Backup Method | Retention | Location |
|-----------|---------------|-----------|----------|
| User uploads | Versioning | 30 days | Same account |
| Critical data | Cross-region copy | 90 days | Paired region |
| Compliance data | Immutable + legal hold | 7 years | Separate account |
| Database backups | Automated + copy | 35 days | Separate account |

### Immutable Storage Policies

| Policy Type | Use Case | Duration |
|-------------|----------|----------|
| Time-based | Compliance retention | Fixed period |
| Legal hold | Litigation | Indefinite |
| WORM | Write-once read-many | Permanent |

## Security Best Practices

### Access Control

| Method | Use Case | Implementation |
|--------|----------|----------------|
| Managed Identity | Azure services | Preferred |
| SAS tokens | Time-limited access | Short expiry |
| Stored access policy | Revocable SAS | Container level |
| RBAC | User/service access | Azure AD |

### Data Protection

| Control | Configuration | Purpose |
|---------|---------------|---------|
| Encryption at rest | Azure-managed or CMK | Data protection |
| Encryption in transit | TLS 1.2+ required | Network protection |
| Private endpoints | VNet integration | No public access |
| Firewall rules | IP/VNet allowlist | Network isolation |

### Compliance Features

| Feature | Compliance | Configuration |
|---------|------------|---------------|
| Immutable storage | SEC 17a-4, FINRA | Policy locked |
| Legal hold | eDiscovery | Tag-based |
| Versioning | Audit trail | Enabled |
| Soft delete | Recovery | 14-365 days |

## Performance Optimization

### Throughput Targets

| Account Type | Max Egress | Max Ingress | Max IOPS |
|--------------|------------|-------------|----------|
| Standard | 50 Gbps | 10 Gbps | 20,000 |
| Premium (Files) | Based on share | Based on share | 100,000 |
| Premium (Block Blob) | 50 Gbps | 10 Gbps | No limit* |

### Optimization Strategies

| Strategy | Benefit | Implementation |
|----------|---------|----------------|
| Parallel uploads | Higher throughput | Multi-part upload |
| CDN caching | Reduced latency | Static content |
| Premium tier | Low latency | Frequently accessed |
| Regional placement | Network proximity | Same region as compute |

## References

- [Azure Blob Storage](https://docs.microsoft.com/azure/storage/blobs/)
- [Storage Redundancy](https://docs.microsoft.com/azure/storage/common/storage-redundancy)
- [Lifecycle Management](https://docs.microsoft.com/azure/storage/blobs/lifecycle-management-overview)
- [Immutable Storage](https://docs.microsoft.com/azure/storage/blobs/immutable-storage-overview)
- [AWS S3](https://aws.amazon.com/s3/)
- [GCP Cloud Storage](https://cloud.google.com/storage)
