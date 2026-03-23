locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  name         = coalesce(var.name_override, "${var.environment}-psql-${local.short_tenant}")
  default_tags = {
    tenant_id   = var.tenant_id
    environment = var.environment
    managed_by  = "opentofu"
    module      = "arxen-infra-module/azure/postgresql"
  }
  tags        = merge(local.default_tags, var.tags)
  cmk_enabled = var.key_vault_key_id != null
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                         = local.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.postgresql_version
  delegated_subnet_id          = var.delegated_subnet_id
  private_dns_zone_id          = var.private_dns_zone_id
  administrator_login          = var.administrator_login
  administrator_password       = var.administrator_password
  sku_name                     = var.sku_name
  storage_mb                   = var.storage_mb
  zone                         = var.zone
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # Security defaults — non-overridable
  backup_retention_days = 35  # SPEC.md mandates 35 days

  # SSL is enforced at the server level via 'require_secure_transport = ON' (Azure default).
  # This cannot be disabled via module parameters — a separate azurerm_postgresql_flexible_server_configuration
  # resource would be required to change it, which is outside the module scope.

  authentication {
    active_directory_auth_enabled = var.entra_auth_enabled
    password_auth_enabled         = true
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
      key_vault_key_id                  = var.key_vault_key_id
      primary_user_assigned_identity_id = var.user_assigned_identity_id
    }
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [zone]
    precondition {
      condition     = var.key_vault_key_id == null || var.user_assigned_identity_id != null
      error_message = "user_assigned_identity_id must be set when key_vault_key_id is provided for CMK encryption."
    }
  }
}
