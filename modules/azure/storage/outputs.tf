output "resource_id" {
  description = "The ARM resource ID of the Storage Account."
  value       = azurerm_storage_account.main.id
  sensitive   = false
}

output "resource_name" {
  description = "The name of the Storage Account as provisioned."
  value       = azurerm_storage_account.main.name
  sensitive   = false
}

output "account_id" {
  # account_id is an ergonomic alias for resource_id.
  description = "The ARM resource ID of the Storage Account (alias for resource_id)."
  value       = azurerm_storage_account.main.id
  sensitive   = false
}

output "primary_blob_endpoint" {
  description = "The primary blob service endpoint URL."
  value       = azurerm_storage_account.main.primary_blob_endpoint
  sensitive   = false
}

output "primary_access_key" {
  description = "The primary storage account access key. Handle as a secret."
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}
