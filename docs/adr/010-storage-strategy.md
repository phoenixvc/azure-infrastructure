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

## References

- [Azure Blob Storage](https://docs.microsoft.com/azure/storage/blobs/)
- [Storage Redundancy](https://docs.microsoft.com/azure/storage/common/storage-redundancy)
- [Lifecycle Management](https://docs.microsoft.com/azure/storage/blobs/lifecycle-management-overview)
