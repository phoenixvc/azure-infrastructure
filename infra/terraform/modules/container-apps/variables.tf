variable "app_name" {
  description = "Container app name"
  type        = string
}

variable "environment_name" {
  description = "Container Apps environment name"
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID for environment"
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Use internal load balancer"
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy"
  type        = bool
  default     = false
}

variable "revision_mode" {
  description = "Revision mode (Single, Multiple)"
  type        = string
  default     = "Single"
}

variable "container_image" {
  description = "Container image"
  type        = string
}

variable "cpu" {
  description = "CPU cores (0.25, 0.5, 1, 2, 4)"
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory (e.g., 1Gi)"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum replicas"
  type        = number
  default     = 10
}

variable "enable_ingress" {
  description = "Enable ingress"
  type        = bool
  default     = true
}

variable "external_ingress" {
  description = "Enable external ingress"
  type        = bool
  default     = true
}

variable "target_port" {
  description = "Container target port"
  type        = number
  default     = 80
}

variable "transport" {
  description = "Transport protocol (http, http2, tcp)"
  type        = string
  default     = "http"
}

variable "user_assigned_identity_ids" {
  description = "User-assigned identity IDs"
  type        = list(string)
  default     = null
}

variable "container_registry_server" {
  description = "Container registry server"
  type        = string
  default     = null
}

variable "container_registry_username" {
  description = "Container registry username"
  type        = string
  default     = null
}

variable "container_registry_password_secret_name" {
  description = "Secret name for registry password"
  type        = string
  default     = null
}

variable "secrets" {
  description = "App secrets"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variable mappings"
  type        = map(string)
  default     = {}
}

variable "liveness_probe" {
  description = "Liveness probe configuration"
  type = object({
    port = number
    path = string
  })
  default = null
}

variable "readiness_probe" {
  description = "Readiness probe configuration"
  type = object({
    port = number
    path = string
  })
  default = null
}

variable "enable_http_scaling" {
  description = "Enable HTTP-based scaling"
  type        = bool
  default     = true
}

variable "http_concurrent_requests" {
  description = "Concurrent requests for scaling"
  type        = string
  default     = "100"
}

variable "custom_scale_rules" {
  description = "Custom KEDA scale rules"
  type = list(object({
    name     = string
    type     = string
    metadata = map(string)
  }))
  default = []
}

variable "enable_dapr" {
  description = "Enable Dapr sidecar"
  type        = bool
  default     = false
}

variable "dapr_app_id" {
  description = "Dapr app ID"
  type        = string
  default     = null
}

variable "dapr_app_port" {
  description = "Dapr app port"
  type        = number
  default     = null
}

variable "dapr_app_protocol" {
  description = "Dapr app protocol (http, grpc)"
  type        = string
  default     = "http"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
