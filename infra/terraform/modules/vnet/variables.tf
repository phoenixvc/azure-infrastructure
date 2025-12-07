variable "name" {
  description = "Virtual network name"
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

variable "address_space" {
  description = "Address space CIDR blocks"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_servers" {
  description = "Custom DNS servers"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Subnet configurations"
  type = list(object({
    name                              = string
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Enabled")
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string))
    }))
  }))
  default = []
}

variable "network_security_groups" {
  description = "NSG configurations"
  type = list(object({
    name = string
    rules = optional(list(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string)
      destination_port_range       = optional(string)
      destination_port_ranges      = optional(list(string))
      source_address_prefix        = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(list(string))
    })), [])
  }))
  default = []
}

variable "nsg_associations" {
  description = "NSG to subnet associations"
  type = list(object({
    subnet_name = string
    nsg_name    = string
  }))
  default = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
