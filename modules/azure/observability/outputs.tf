output "resource_id" {
  description = "The ARM resource ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.main.id
  sensitive   = false
}

output "resource_name" {
  description = "The name of the Log Analytics Workspace as provisioned."
  value       = azurerm_log_analytics_workspace.main.name
  sensitive   = false
}

output "workspace_id" {
  description = "The Log Analytics Workspace ID (GUID) used by AKS and diagnostic settings."
  value       = azurerm_log_analytics_workspace.main.workspace_id
  sensitive   = false
}
