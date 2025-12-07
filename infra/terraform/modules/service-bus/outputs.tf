output "id" {
  description = "Service Bus namespace resource ID"
  value       = azurerm_servicebus_namespace.main.id
}

output "name" {
  description = "Service Bus namespace name"
  value       = azurerm_servicebus_namespace.main.name
}

output "endpoint" {
  description = "Service Bus endpoint"
  value       = azurerm_servicebus_namespace.main.endpoint
}

output "primary_connection_string" {
  description = "Primary connection string (Listen/Send)"
  value       = azurerm_servicebus_namespace_authorization_rule.app_access.primary_connection_string
  sensitive   = true
}

output "manage_connection_string" {
  description = "Manage connection string"
  value       = azurerm_servicebus_namespace_authorization_rule.manage_access.primary_connection_string
  sensitive   = true
}

output "queue_names" {
  description = "List of queue names"
  value       = [for q in azurerm_servicebus_queue.queues : q.name]
}

output "topic_names" {
  description = "List of topic names"
  value       = [for t in azurerm_servicebus_topic.topics : t.name]
}
