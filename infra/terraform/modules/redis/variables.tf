variable "name" {
  description = "Redis cache name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku_name" {
  description = "SKU name (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "family" {
  description = "SKU family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"
}

variable "capacity" {
  description = "Cache size (0-6 for C family, 1-5 for P family)"
  type        = number
  default     = 1
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "6"
}

variable "maxmemory_policy" {
  description = "Eviction policy"
  type        = string
  default     = "volatile-lru"
}

variable "maxmemory_reserved" {
  description = "Memory reserved for non-cache operations (MB)"
  type        = number
  default     = 50
}

variable "maxfragmentationmemory_reserved" {
  description = "Memory reserved for fragmentation (MB)"
  type        = number
  default     = 50
}

variable "notify_keyspace_events" {
  description = "Keyspace notification events"
  type        = string
  default     = ""
}

variable "aof_backup_enabled" {
  description = "Enable AOF persistence (Premium only)"
  type        = bool
  default     = false
}

variable "rdb_backup_enabled" {
  description = "Enable RDB persistence (Premium only)"
  type        = bool
  default     = false
}

variable "rdb_backup_frequency" {
  description = "RDB backup frequency in minutes"
  type        = number
  default     = 60
}

variable "rdb_storage_connection_string" {
  description = "Storage connection string for RDB backups"
  type        = string
  default     = null
  sensitive   = true
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint (Premium only)"
  type        = string
  default     = null
}

variable "replicas_per_master" {
  description = "Replicas per master (Premium only)"
  type        = number
  default     = null
}

variable "shard_count" {
  description = "Number of shards for clustering (Premium only)"
  type        = number
  default     = null
}

variable "zones" {
  description = "Availability zones (Premium only)"
  type        = list(string)
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
