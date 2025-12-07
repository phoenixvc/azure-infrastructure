variable "name" {
  description = "PostgreSQL server name"
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
  description = "SKU name (e.g., B_Standard_B1ms, GP_Standard_D2s_v3)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Backup retention in days (7-35)"
  type        = number
  default     = 7
}

variable "geo_redundant_backup" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

variable "administrator_login" {
  description = "Administrator login name"
  type        = string
}

variable "administrator_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "availability_zone" {
  description = "Availability zone (1, 2, or 3)"
  type        = string
  default     = "1"
}

variable "high_availability_mode" {
  description = "High availability mode (Disabled, SameZone, ZoneRedundant)"
  type        = string
  default     = "Disabled"
}

variable "standby_availability_zone" {
  description = "Standby availability zone for HA"
  type        = string
  default     = "2"
}

variable "delegated_subnet_id" {
  description = "Subnet ID for private access"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID"
  type        = string
  default     = null
}

variable "timezone" {
  description = "Server timezone"
  type        = string
  default     = "UTC"
}

variable "allow_azure_services" {
  description = "Allow Azure services to access"
  type        = bool
  default     = false
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
