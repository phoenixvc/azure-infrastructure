variable "name" {
  description = "Log Analytics workspace name"
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
  description = "SKU (Free, PerGB2018, Premium, Standard, Standalone, Unlimited, CapacityReservation)"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Data retention in days (30-730)"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB (-1 for unlimited)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Enable internet ingestion"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable internet queries"
  type        = bool
  default     = true
}

variable "create_application_insights" {
  description = "Create Application Insights"
  type        = bool
  default     = true
}

variable "application_insights_name" {
  description = "Application Insights name"
  type        = string
  default     = null
}

variable "application_type" {
  description = "Application Insights type"
  type        = string
  default     = "web"
}

variable "app_insights_retention_days" {
  description = "Application Insights retention days"
  type        = number
  default     = 90
}

variable "sampling_percentage" {
  description = "Sampling percentage (0-100)"
  type        = number
  default     = 100
}

variable "disable_ip_masking" {
  description = "Disable IP masking"
  type        = bool
  default     = false
}

variable "solutions" {
  description = "Log Analytics solutions to install"
  type        = list(string)
  default     = []
  # Common solutions: "ContainerInsights", "AzureActivity", "SecurityInsights"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
