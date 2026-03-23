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

  lifecycle {
    precondition {
      condition     = var.public_network_access_enabled == true || var.private_endpoint_subnet_id != null
      error_message = "private_endpoint_subnet_id must be set when public_network_access_enabled is false."
    }
  }
}

# Private endpoint and DNS zone for the AI workspace (enabled when private_endpoint_subnet_id is provided)
resource "azurerm_private_dns_zone" "workspace" {
  count               = var.private_endpoint_subnet_id != null ? 1 : 0
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "workspace" {
  count                 = var.private_endpoint_subnet_id != null ? 1 : 0
  name                  = "pdnslink-mlws-${local.short_tenant}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.workspace[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "workspace" {
  count               = var.private_endpoint_subnet_id != null ? 1 : 0
  name                = "pep-mlws-${local.short_tenant}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-mlws-${local.short_tenant}"
    private_connection_resource_id = azurerm_machine_learning_workspace.main.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-mlws"
    private_dns_zone_ids = [azurerm_private_dns_zone.workspace[0].id]
  }
}
