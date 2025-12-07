variable "name" {
  description = "Service Bus namespace name"
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

variable "sku" {
  description = "SKU tier (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "capacity" {
  description = "Messaging units for Premium (1, 2, 4, 8, 16)"
  type        = number
  default     = 1
}

variable "premium_messaging_partitions" {
  description = "Premium partitions (1, 2, 4)"
  type        = number
  default     = 1
}

variable "zone_redundant" {
  description = "Enable zone redundancy (Premium only)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "local_auth_enabled" {
  description = "Enable SAS authentication"
  type        = bool
  default     = true
}

variable "queues" {
  description = "List of queues to create"
  type = list(object({
    name                         = string
    max_size_in_megabytes        = optional(number, 1024)
    enable_partitioning          = optional(bool, false)
    requires_duplicate_detection = optional(bool, false)
    requires_session             = optional(bool, false)
    dead_lettering_on_message_expiration = optional(bool, true)
    max_delivery_count           = optional(number, 10)
    lock_duration                = optional(string, "PT1M")
    default_message_ttl          = optional(string, "P14D")
  }))
  default = []
}

variable "topics" {
  description = "List of topics to create"
  type = list(object({
    name                         = string
    max_size_in_megabytes        = optional(number, 1024)
    enable_partitioning          = optional(bool, false)
    requires_duplicate_detection = optional(bool, false)
    default_message_ttl          = optional(string, "P14D")
    subscriptions                = optional(list(string), [])
  }))
  default = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
