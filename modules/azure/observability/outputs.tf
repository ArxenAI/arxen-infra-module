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

output "application_insights_id" {
  description = "The ARM resource ID of the Application Insights instance. null when application_insights_enabled is false."
  value       = var.application_insights_enabled ? azurerm_application_insights.main[0].id : null
  sensitive   = false
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key. Handle as a secret. null when application_insights_enabled is false."
  value       = var.application_insights_enabled ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string. Handle as a secret. null when application_insights_enabled is false."
  value       = var.application_insights_enabled ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}
