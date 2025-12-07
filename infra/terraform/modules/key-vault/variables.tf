variable "name" {
  description = "Key Vault name"
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
  description = "SKU name (standard, premium)"
  type        = string
  default     = "standard"
}

variable "enabled_for_deployment" {
  description = "Allow VMs to retrieve certificates"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow disk encryption to retrieve secrets"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow ARM to retrieve secrets"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Use RBAC instead of access policies"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention (7-90 days)"
  type        = number
  default     = 90
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
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

variable "secrets" {
  description = "Secrets to create"
  type = map(object({
    value           = string
    content_type    = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
