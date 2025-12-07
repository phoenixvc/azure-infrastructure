# =============================================================================
# Azure Redis Cache Module
# =============================================================================
# Terraform equivalent of infra/modules/redis-cache/main.bicep
#
# Multi-cloud alternatives:
# - AWS: aws_elasticache_replication_group with engine = "redis"
# - GCP: google_redis_instance

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

# -----------------------------------------------------------------------------
# Redis Cache
# -----------------------------------------------------------------------------

resource "azurerm_redis_cache" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  capacity            = var.capacity
  family              = var.family
  sku_name            = var.sku_name

  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_version = var.redis_version

  # Redis configuration
  redis_configuration {
    maxmemory_policy                  = var.maxmemory_policy
    maxmemory_reserved                = var.sku_name == "Premium" ? var.maxmemory_reserved : null
    maxfragmentationmemory_reserved   = var.sku_name == "Premium" ? var.maxfragmentationmemory_reserved : null
    notify_keyspace_events            = var.notify_keyspace_events
    aof_backup_enabled                = var.sku_name == "Premium" ? var.aof_backup_enabled : false
    rdb_backup_enabled                = var.sku_name == "Premium" ? var.rdb_backup_enabled : false
    rdb_backup_frequency              = var.sku_name == "Premium" && var.rdb_backup_enabled ? var.rdb_backup_frequency : null
    rdb_storage_connection_string     = var.sku_name == "Premium" && var.rdb_backup_enabled ? var.rdb_storage_connection_string : null
  }

  # Private endpoint subnet
  subnet_id = var.subnet_id

  # Replicas (Premium only)
  replicas_per_master = var.sku_name == "Premium" ? var.replicas_per_master : null
  shard_count         = var.sku_name == "Premium" ? var.shard_count : null

  # Zones (Premium only)
  zones = var.sku_name == "Premium" ? var.zones : null

  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

resource "azurerm_redis_firewall_rule" "allowed_ips" {
  for_each = { for idx, ip in var.allowed_ip_addresses : idx => ip }

  name            = "AllowIP-${each.key}"
  redis_cache_name = azurerm_redis_cache.main.name
  resource_group_name = var.resource_group_name
  start_ip        = each.value
  end_ip          = each.value
}
