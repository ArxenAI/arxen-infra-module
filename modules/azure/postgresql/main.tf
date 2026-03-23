locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  name         = coalesce(var.name_override, "${var.environment}-psql-${local.short_tenant}")
  default_tags = {
    tenant_id   = var.tenant_id
    environment = var.environment
    managed_by  = "opentofu"
    module      = "arxen-infra-module/azure/postgresql"
  }
  tags = merge(local.default_tags, var.tags)
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
  backup_retention_days = 35 # SPEC.md mandates 35 days

  authentication {
    active_directory_auth_enabled = false
    password_auth_enabled         = true
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      # zone may be changed by Azure during maintenance — ignore to prevent unnecessary recreation
      zone,
    ]
  }
}
