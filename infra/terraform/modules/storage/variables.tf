variable "name" {
  description = "Storage account name (3-24 chars, lowercase alphanumeric)"
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

variable "account_tier" {
  description = "Account tier (Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Account kind (StorageV2, BlobStorage, BlockBlobStorage, FileStorage)"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Access tier (Hot, Cool)"
  type        = string
  default     = "Hot"
}

variable "allow_blob_public_access" {
  description = "Allow public access to blobs"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access keys"
  type        = bool
  default     = true
}

variable "is_hns_enabled" {
  description = "Enable hierarchical namespace (Data Lake)"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = false
}

variable "blob_delete_retention_days" {
  description = "Blob soft delete retention days (0 to disable)"
  type        = number
  default     = 7
}

variable "container_delete_retention_days" {
  description = "Container soft delete retention days (0 to disable)"
  type        = number
  default     = 7
}

variable "cors_rules" {
  description = "CORS rules for blob service"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

variable "network_default_action" {
  description = "Default network action (Allow, Deny)"
  type        = string
  default     = "Allow"
}

variable "allowed_ip_addresses" {
  description = "Allowed IP addresses"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Allowed subnet IDs"
  type        = list(string)
  default     = []
}

variable "containers" {
  description = "Blob containers to create"
  type = list(object({
    name        = string
    access_type = optional(string, "private")
  }))
  default = []
}

variable "file_shares" {
  description = "File shares to create"
  type = list(object({
    name        = string
    quota       = optional(number, 100)
    access_tier = optional(string, "Hot")
  }))
  default = []
}

variable "queues" {
  description = "Storage queues to create"
  type        = list(string)
  default     = []
}

variable "tables" {
  description = "Storage tables to create"
  type        = list(string)
  default     = []
}

variable "lifecycle_rules" {
  description = "Lifecycle management rules"
  type = list(object({
    name         = string
    prefix_match = optional(list(string), [])
    blob_types   = optional(list(string), ["blockBlob"])
    base_blob = optional(object({
      tier_to_cool_after_days    = optional(number)
      tier_to_archive_after_days = optional(number)
      delete_after_days          = optional(number)
    }))
  }))
  default = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
