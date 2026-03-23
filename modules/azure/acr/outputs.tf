output "resource_id" {
  description = "The ARM resource ID of the Container Registry."
  value       = azurerm_container_registry.main.id
  sensitive   = false
}

output "resource_name" {
  description = "The name of the Container Registry as provisioned."
  value       = azurerm_container_registry.main.name
  sensitive   = false
}

output "registry_id" {
  # registry_id is an ergonomic alias for resource_id.
  description = "The ARM resource ID of the Container Registry (alias for resource_id)."
  value       = azurerm_container_registry.main.id
  sensitive   = false
}

output "login_server" {
  description = "The login server FQDN of the Container Registry (e.g. <name>.azurecr.io)."
  value       = azurerm_container_registry.main.login_server
  sensitive   = false
}
