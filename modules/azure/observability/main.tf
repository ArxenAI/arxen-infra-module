locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  log_name     = coalesce(var.name_override, "${var.environment}-log-${local.short_tenant}")
  appi_name    = "${var.environment}-appi-${local.short_tenant}"
  default_tags = {
    tenant_id   = var.tenant_id
    environment = var.environment
    managed_by  = "opentofu"
    module      = "arxen-infra-module/azure/observability"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = local.tags
}

# Application Insights in workspace-based mode (workspace_id required).
# Workspace-based mode stores telemetry in the Log Analytics Workspace, enabling
# cross-resource queries and unified retention management.
resource "azurerm_application_insights" "main" {
  count = var.application_insights_enabled ? 1 : 0

  name                = local.appi_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = var.application_insights_type
  tags                = local.tags
}
