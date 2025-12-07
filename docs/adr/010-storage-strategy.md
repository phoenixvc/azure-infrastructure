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

### Storage Account Bicep Module

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'  // Or Standard_GRS for geo-redundancy
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetId
        }
      ]
    }
    encryption: {
      services: {
        blob: { enabled: true }
        file: { enabled: true }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Blob containers
resource uploadsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/uploads'
  properties: {
    publicAccess: 'None'
  }
}
```

### Lifecycle Management Policy

```bicep
resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'logs-to-cool'
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: ['blockBlob']
              prefixMatch: ['logs/']
            }
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 30
                }
                tierToArchive: {
                  daysAfterModificationGreaterThan: 90
                }
                delete: {
                  daysAfterModificationGreaterThan: 365
                }
              }
            }
          }
        }
      ]
    }
  }
}
```

### Python Storage Abstraction

```python
# src/api/app/storage/base.py
from abc import ABC, abstractmethod
from typing import BinaryIO, Optional, List

class BaseStorageProvider(ABC):
    """Abstract storage provider interface."""

    @abstractmethod
    async def upload(
        self,
        container: str,
        blob_name: str,
        data: BinaryIO,
        content_type: Optional[str] = None,
    ) -> str:
        """Upload a blob and return URL."""
        pass

    @abstractmethod
    async def download(
        self,
        container: str,
        blob_name: str,
    ) -> bytes:
        """Download blob content."""
        pass

    @abstractmethod
    async def delete(
        self,
        container: str,
        blob_name: str,
    ) -> bool:
        """Delete a blob."""
        pass

    @abstractmethod
    async def list_blobs(
        self,
        container: str,
        prefix: Optional[str] = None,
    ) -> List[str]:
        """List blobs in container."""
        pass

    @abstractmethod
    async def get_sas_url(
        self,
        container: str,
        blob_name: str,
        expiry_hours: int = 1,
    ) -> str:
        """Generate SAS URL for blob."""
        pass
```

### Azure Blob Implementation

```python
from azure.storage.blob.aio import BlobServiceClient
from azure.storage.blob import generate_blob_sas, BlobSasPermissions
from datetime import datetime, timedelta

class AzureBlobStorage(BaseStorageProvider):
    def __init__(self, connection_string: str):
        self.client = BlobServiceClient.from_connection_string(connection_string)

    async def upload(
        self,
        container: str,
        blob_name: str,
        data: BinaryIO,
        content_type: Optional[str] = None,
    ) -> str:
        blob_client = self.client.get_blob_client(container, blob_name)
        await blob_client.upload_blob(
            data,
            content_type=content_type,
            overwrite=True,
        )
        return blob_client.url

    async def get_sas_url(
        self,
        container: str,
        blob_name: str,
        expiry_hours: int = 1,
    ) -> str:
        sas_token = generate_blob_sas(
            account_name=self.client.account_name,
            container_name=container,
            blob_name=blob_name,
            account_key=self.client.credential.account_key,
            permission=BlobSasPermissions(read=True),
            expiry=datetime.utcnow() + timedelta(hours=expiry_hours),
        )
        return f"{self.client.url}{container}/{blob_name}?{sas_token}"
```

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
