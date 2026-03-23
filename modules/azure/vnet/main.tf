locals {
  short_tenant = substr(var.tenant_id, 0, 8)
  name         = coalesce(var.name_override, "${var.environment}-vnet-${local.short_tenant}")
  default_tags = {
    tenant_id   = var.tenant_id
    environment = var.environment
    managed_by  = "opentofu"
    module      = "arxen-infra-module/azure/vnet"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_virtual_network" "main" {
  name                = local.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = local.tags
}

resource "azurerm_subnet" "aks_nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_nodes_cidr]
}

resource "azurerm_subnet" "aks_pods" {
  name                 = "snet-aks-pods"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_pods_cidr]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_endpoints_cidr]
  private_endpoint_network_policies_enabled = false
}

# count is used here instead of for_each because this is a single conditional resource
# controlled by a boolean toggle. for_each would require an unnecessary set/map wrapper
# for a one-element collection.
resource "azurerm_subnet" "appgw" {
  count                = var.enable_appgw_subnet ? 1 : 0
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.appgw_cidr]
}

# NSGs are created without custom security rules. Azure's built-in default rules
# block all inbound internet traffic. Custom rules should be added by the caller
# via azurerm_network_security_rule resources referencing these NSG IDs, or
# via the outputs. See README for details.
resource "azurerm_network_security_group" "aks_nodes" {
  name                = "nsg-aks-nodes-${local.short_tenant}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_network_security_group" "aks_pods" {
  name                = "nsg-aks-pods-${local.short_tenant}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-private-endpoints-${local.short_tenant}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

# count is used here instead of for_each because this is a single conditional resource
# controlled by a boolean toggle. for_each would require an unnecessary set/map wrapper
# for a one-element collection.
resource "azurerm_network_security_group" "appgw" {
  count               = var.enable_appgw_subnet ? 1 : 0
  name                = "nsg-appgw-${local.short_tenant}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "aks_nodes" {
  subnet_id                 = azurerm_subnet.aks_nodes.id
  network_security_group_id = azurerm_network_security_group.aks_nodes.id
}

resource "azurerm_subnet_network_security_group_association" "aks_pods" {
  subnet_id                 = azurerm_subnet.aks_pods.id
  network_security_group_id = azurerm_network_security_group.aks_pods.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

# count is used here instead of for_each because this is a single conditional resource
# controlled by a boolean toggle. for_each would require an unnecessary set/map wrapper
# for a one-element collection.
resource "azurerm_subnet_network_security_group_association" "appgw" {
  count                     = var.enable_appgw_subnet ? 1 : 0
  subnet_id                 = azurerm_subnet.appgw[0].id
  network_security_group_id = azurerm_network_security_group.appgw[0].id
}
