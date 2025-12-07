# Terraform Modules

Cloud-agnostic and Azure-specific Terraform modules equivalent to the Bicep modules.

## Module Overview

| Module | Azure Resource | AWS Equivalent | GCP Equivalent |
|--------|---------------|----------------|----------------|
| `postgres` | PostgreSQL Flexible | RDS PostgreSQL | Cloud SQL |
| `redis` | Azure Cache for Redis | ElastiCache | Memorystore |
| `service-bus` | Service Bus | SQS/SNS | Pub/Sub |
| `key-vault` | Key Vault | Secrets Manager | Secret Manager |
| `container-apps` | Container Apps | App Runner/ECS | Cloud Run |
| `storage` | Blob Storage | S3 | Cloud Storage |
| `vnet` | Virtual Network | VPC | VPC |
| `log-analytics` | Log Analytics | CloudWatch | Cloud Logging |

## Usage

```hcl
module "postgres" {
  source = "./modules/postgres"

  name                = "myapp-db"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"

  sku_name            = "B_Standard_B1ms"
  storage_mb          = 32768

  administrator_login    = "adminuser"
  administrator_password = var.db_password

  tags = {
    Environment = "production"
  }
}
```

## Prerequisites

- Terraform >= 1.5.0
- Azure CLI authenticated (`az login`)
- Provider configuration:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

provider "azurerm" {
  features {}
}
```

## Multi-Cloud Support

Each module includes comments showing equivalent configurations for AWS and GCP.
See individual module READMEs for cloud-specific examples.
