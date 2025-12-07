output "id" {
  description = "Log Analytics workspace resource ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "workspace_id" {
  description = "Log Analytics workspace ID (GUID)"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "primary_shared_key" {
  description = "Primary shared key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "application_insights_id" {
  description = "Application Insights resource ID"
  value       = var.create_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = var.create_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = var.create_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}
