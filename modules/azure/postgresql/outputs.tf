output "resource_id" {
  description = "The ARM resource ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.id
  sensitive   = false
}

output "resource_name" {
  description = "The name of the PostgreSQL Flexible Server as provisioned."
  value       = azurerm_postgresql_flexible_server.main.name
  sensitive   = false
}

output "server_id" {
  # server_id is an ergonomic alias for resource_id.
  description = "The ARM resource ID of the PostgreSQL Flexible Server (alias for resource_id)."
  value       = azurerm_postgresql_flexible_server.main.id
  sensitive   = false
}

output "fqdn" {
  description = "The fully-qualified domain name (FQDN) of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
  sensitive   = false
}

output "connection_string" {
  description = "PostgreSQL connection string including credentials. Handle as a secret."
  value       = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:${var.administrator_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/postgres?sslmode=require"
  sensitive   = true
}
