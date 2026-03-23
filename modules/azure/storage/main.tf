locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  # Storage account names: 3-24 chars, lowercase alphanumeric only (no hyphens).
  # Auto-generated name strips hyphens and lowercases to ensure compliance.
  name = coalesce(var.name_override, lower(replace("${var.environment}st${local.short_tenant}", "-", "")))
  default_tags = {
    tenant_id   = var.tenant_id
    environment = var.environment
    managed_by  = "opentofu"
    module      = "arxen-infra-module/azure/storage"
  }
  tags        = merge(local.default_tags, var.tags)
  cmk_enabled = var.key_vault_key_id != null
}

resource "azurerm_storage_account" "main" {
  name                          = local.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.account_replication_type

  # Security defaults — non-overridable
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
  # Security defaults — non-overridable (CMK configured via dynamic blocks below)
  public_network_access_enabled = false

  blob_properties {
    versioning_enabled = true
  }

  dynamic "identity" {
    for_each = local.cmk_enabled ? [1] : []
    iterator = id
    content {
      type         = "UserAssigned"
      identity_ids = [var.user_assigned_identity_id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = local.cmk_enabled ? [1] : []
    iterator = cmk
    content {
      key_vault_key_id          = var.key_vault_key_id
      user_assigned_identity_id = var.user_assigned_identity_id
    }
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition     = var.key_vault_key_id == null || var.user_assigned_identity_id != null
      error_message = "user_assigned_identity_id must be set when key_vault_key_id is provided for CMK encryption."
    }
  }
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "pdnslink-st-${local.short_tenant}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pep-st-${local.short_tenant}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-st-${local.short_tenant}"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-st"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
