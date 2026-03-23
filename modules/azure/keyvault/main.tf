locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  name         = coalesce(var.name_override, "${var.environment}-kv-${local.short_tenant}")
  default_tags = {
    tenant_id   = var.tenant_id
    environment = var.environment
    managed_by  = "opentofu"
    module      = "arxen-infra-module/azure/keyvault"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_key_vault" "main" {
  name                = local.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.azure_ad_tenant_id
  sku_name            = var.sku_name

  # Security defaults — non-overridable
  public_network_access_enabled = false
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enable_rbac_authorization     = true

  tags = local.tags
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "pdnslink-kv-${local.short_tenant}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pep-kv-${local.short_tenant}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-kv-${local.short_tenant}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}
