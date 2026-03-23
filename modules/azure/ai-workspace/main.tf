locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  name         = coalesce(var.name_override, "${var.environment}-mlws-${local.short_tenant}")
  default_tags = {
    tenant_id   = var.tenant_id
    environment = var.environment
    managed_by  = "opentofu"
    module      = "arxen-infra-module/azure/ai-workspace"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_machine_learning_workspace" "main" {
  name                          = local.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  container_registry_id         = var.container_registry_id
  public_network_access_enabled = var.public_network_access_enabled
  image_build_compute_name      = var.image_build_compute_name
  application_insights_id       = var.application_insights_id
  tags                          = local.tags

  identity {
    type = "SystemAssigned"
  }
}
