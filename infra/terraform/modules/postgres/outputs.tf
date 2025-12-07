output "server_id" {
  description = "PostgreSQL server resource ID"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "PostgreSQL server name"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_name" {
  description = "Database name"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.administrator_login}@${azurerm_postgresql_flexible_server.main.name}:${var.administrator_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  sensitive   = true
}

output "jdbc_connection_string" {
  description = "JDBC connection string"
  value       = "jdbc:postgresql://${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
}
