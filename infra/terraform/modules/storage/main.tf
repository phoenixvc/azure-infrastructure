# =============================================================================
# Azure Storage Account Module
# =============================================================================
# Terraform equivalent of infra/modules/storage/main.bicep
#
# Multi-cloud alternatives:
# - AWS: aws_s3_bucket
# - GCP: google_storage_bucket

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

# -----------------------------------------------------------------------------
# Storage Account
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = var.account_kind

  access_tier = var.access_tier

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = var.allow_blob_public_access
  shared_access_key_enabled       = var.shared_access_key_enabled

  # Enable hierarchical namespace for Data Lake
  is_hns_enabled = var.is_hns_enabled

  # HTTPS only
  https_traffic_only_enabled = true

  # Blob properties
  blob_properties {
    versioning_enabled = var.enable_versioning

    dynamic "delete_retention_policy" {
      for_each = var.blob_delete_retention_days > 0 ? [1] : []
      content {
        days = var.blob_delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_delete_retention_days > 0 ? [1] : []
      content {
        days = var.container_delete_retention_days
      }
    }

    dynamic "cors_rule" {
      for_each = var.cors_rules
      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
  }

  # Network rules
  network_rules {
    default_action             = var.network_default_action
    bypass                     = ["AzureServices"]
    ip_rules                   = var.allowed_ip_addresses
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Containers
# -----------------------------------------------------------------------------

resource "azurerm_storage_container" "containers" {
  for_each = { for c in var.containers : c.name => c }

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = lookup(each.value, "access_type", "private")
}

# -----------------------------------------------------------------------------
# File Shares
# -----------------------------------------------------------------------------

resource "azurerm_storage_share" "shares" {
  for_each = { for s in var.file_shares : s.name => s }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.main.name
  quota                = lookup(each.value, "quota", 100)
  access_tier          = lookup(each.value, "access_tier", "Hot")
}

# -----------------------------------------------------------------------------
# Queues
# -----------------------------------------------------------------------------

resource "azurerm_storage_queue" "queues" {
  for_each = toset(var.queues)

  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# -----------------------------------------------------------------------------
# Tables
# -----------------------------------------------------------------------------

resource "azurerm_storage_table" "tables" {
  for_each = toset(var.tables)

  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# -----------------------------------------------------------------------------
# Lifecycle Management
# -----------------------------------------------------------------------------

resource "azurerm_storage_management_policy" "lifecycle" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = true

      filters {
        prefix_match = lookup(rule.value, "prefix_match", [])
        blob_types   = lookup(rule.value, "blob_types", ["blockBlob"])
      }

      actions {
        dynamic "base_blob" {
          for_each = lookup(rule.value, "base_blob", null) != null ? [rule.value.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = lookup(base_blob.value, "tier_to_cool_after_days", null)
            tier_to_archive_after_days_since_modification_greater_than = lookup(base_blob.value, "tier_to_archive_after_days", null)
            delete_after_days_since_modification_greater_than          = lookup(base_blob.value, "delete_after_days", null)
          }
        }
      }
    }
  }
}
