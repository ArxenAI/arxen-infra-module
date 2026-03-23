output "resource_id" {
  description = "The ARM resource ID of the Azure ML Workspace."
  value       = azurerm_machine_learning_workspace.main.id
  sensitive   = false
}

output "resource_name" {
  description = "The name of the Azure ML Workspace as provisioned."
  value       = azurerm_machine_learning_workspace.main.name
  sensitive   = false
}

output "workspace_id" {
  # workspace_id is an ergonomic alias for resource_id.
  description = "The ARM resource ID of the Azure ML Workspace (alias for resource_id)."
  value       = azurerm_machine_learning_workspace.main.id
  sensitive   = false
}

output "discovery_url" {
  description = "The workspace discovery URL used by Azure ML SDK clients."
  value       = try(azurerm_machine_learning_workspace.main.discovery_url, "")
  sensitive   = false
}
