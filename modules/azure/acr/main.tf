locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  # ACR names: 5-50 chars, alphanumeric only (no hyphens). Remove hyphens from generated name.
  name_raw     = coalesce(var.name_override, "${var.environment}acr${local.short_tenant}")
  name         = replace(local.name_raw, "-", "")
  default_tags = {
    tenant_id   = var.tenant_id
    environment = var.environment
    managed_by  = "opentofu"
    module      = "arxen-infra-module/azure/acr"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_container_registry" "main" {
  name                          = local.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"  # Required for private endpoints
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = local.tags

  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
    }
  }
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "pdnslink-acr-${local.short_tenant}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pep-acr-${local.short_tenant}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-acr-${local.short_tenant}"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}
