output "environment_id" {
  description = "Container Apps environment ID"
  value       = azurerm_container_app_environment.main.id
}

output "environment_name" {
  description = "Container Apps environment name"
  value       = azurerm_container_app_environment.main.name
}

output "app_id" {
  description = "Container app ID"
  value       = azurerm_container_app.main.id
}

output "app_name" {
  description = "Container app name"
  value       = azurerm_container_app.main.name
}

output "fqdn" {
  description = "Container app FQDN"
  value       = var.enable_ingress ? azurerm_container_app.main.latest_revision_fqdn : null
}

output "url" {
  description = "Container app URL"
  value       = var.enable_ingress ? "https://${azurerm_container_app.main.latest_revision_fqdn}" : null
}

output "principal_id" {
  description = "System-assigned identity principal ID"
  value       = try(azurerm_container_app.main.identity[0].principal_id, null)
}
