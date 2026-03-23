output "resource_id" {
  description = "The ARM resource ID of the Key Vault."
  value       = azurerm_key_vault.main.id
  sensitive   = false
}

output "resource_name" {
  description = "The name of the Key Vault as provisioned."
  value       = azurerm_key_vault.main.name
  sensitive   = false
}

output "vault_id" {
  # vault_id is an ergonomic alias for resource_id for use in downstream module configurations.
  description = "The ARM resource ID of the Key Vault (alias for resource_id)."
  value       = azurerm_key_vault.main.id
  sensitive   = false
}

output "vault_uri" {
  description = "The HTTPS URI of the Key Vault (e.g. https://<name>.vault.azure.net/)."
  value       = azurerm_key_vault.main.vault_uri
  sensitive   = false
}
