output "id" {
  description = "Virtual network resource ID"
  value       = azurerm_virtual_network.main.id
}

output "name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.main.name
}

output "address_space" {
  description = "Address space"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for s in azurerm_subnet.subnets : s.name => s.id }
}

output "nsg_ids" {
  description = "Map of NSG names to IDs"
  value       = { for nsg in azurerm_network_security_group.nsgs : nsg.name => nsg.id }
}
