locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  name         = coalesce(var.name_override, "${var.environment}-aks-${local.short_tenant}")
  default_tags = {
    tenant_id       = var.tenant_id
    environment     = var.environment
    managed_by      = "opentofu"
    module          = "arxen-infra-module/azure/aks"
    subscription_id = var.subscription_id
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.environment}-aks-${local.short_tenant}"
  kubernetes_version  = var.kubernetes_version
  tags                = local.tags

  # Security defaults — non-overridable per SPEC.md
  private_cluster_enabled           = true
  azure_policy_enabled              = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true
  local_account_disabled            = true

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = var.vnet_subnet_id
    # Ephemeral OS disks reduce attack surface and improve node startup time
    os_disk_type = "Ephemeral"
    tags         = local.tags
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
    tenant_id              = var.azure_ad_tenant_id
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }
}
