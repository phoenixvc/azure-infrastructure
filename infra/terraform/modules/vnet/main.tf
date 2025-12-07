# =============================================================================
# Azure Virtual Network Module
# =============================================================================
# Terraform equivalent of infra/modules/vnet/main.bicep
#
# Multi-cloud alternatives:
# - AWS: aws_vpc + aws_subnet
# - GCP: google_compute_network + google_compute_subnetwork

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

# -----------------------------------------------------------------------------
# Virtual Network
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  address_space = var.address_space
  dns_servers   = var.dns_servers

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "subnets" {
  for_each = { for s in var.subnets : s.name => s }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = each.value.address_prefixes

  service_endpoints = lookup(each.value, "service_endpoints", [])

  private_endpoint_network_policies = lookup(each.value, "private_endpoint_network_policies", "Enabled")

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = lookup(delegation.value, "actions", ["Microsoft.Network/virtualNetworks/subnets/action"])
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Network Security Groups
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "nsgs" {
  for_each = { for nsg in var.network_security_groups : nsg.name => nsg }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location

  dynamic "security_rule" {
    for_each = lookup(each.value, "rules", [])
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = lookup(security_rule.value, "source_port_range", "*")
      destination_port_range     = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges    = lookup(security_rule.value, "destination_port_ranges", null)
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes    = lookup(security_rule.value, "source_address_prefixes", null)
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", null)
      destination_address_prefixes = lookup(security_rule.value, "destination_address_prefixes", null)
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# NSG Associations
# -----------------------------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  for_each = { for assoc in var.nsg_associations : assoc.subnet_name => assoc }

  subnet_id                 = azurerm_subnet.subnets[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.value.nsg_name].id
}
