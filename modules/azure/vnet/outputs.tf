output "resource_id" {
  description = "The ARM resource ID of the Virtual Network."
  value       = azurerm_virtual_network.main.id
  sensitive   = false
}

output "resource_name" {
  description = "The name of the Virtual Network as provisioned."
  value       = azurerm_virtual_network.main.name
  sensitive   = false
}

# vnet_id is an ergonomic alias for resource_id, allowing callers to use
# module.vnet.vnet_id which reads more clearly in networking contexts.
output "vnet_id" {
  description = "The ARM resource ID of the Virtual Network (alias for resource_id)."
  value       = azurerm_virtual_network.main.id
  sensitive   = false
}

output "aks_nodes_subnet_id" {
  description = "Subnet ID for the AKS node pool."
  value       = azurerm_subnet.aks_nodes.id
  sensitive   = false
}

output "aks_pods_subnet_id" {
  description = "Subnet ID for the AKS pod CIDR (CNI)."
  value       = azurerm_subnet.aks_pods.id
  sensitive   = false
}

output "private_endpoints_subnet_id" {
  description = "Subnet ID for private endpoints."
  value       = azurerm_subnet.private_endpoints.id
  sensitive   = false
}

output "appgw_subnet_id" {
  description = "Subnet ID for the Application Gateway. null if enable_appgw_subnet is false."
  value       = var.enable_appgw_subnet ? azurerm_subnet.appgw[0].id : null
  sensitive   = false
}

output "aks_nodes_nsg_id" {
  description = "NSG resource ID for the AKS nodes subnet. Use to add custom security rules."
  value       = azurerm_network_security_group.aks_nodes.id
  sensitive   = false
}

output "aks_pods_nsg_id" {
  description = "NSG resource ID for the AKS pods subnet. Use to add custom security rules."
  value       = azurerm_network_security_group.aks_pods.id
  sensitive   = false
}

output "private_endpoints_nsg_id" {
  description = "NSG resource ID for the private endpoints subnet. Use to add custom security rules."
  value       = azurerm_network_security_group.private_endpoints.id
  sensitive   = false
}

output "appgw_nsg_id" {
  description = "NSG resource ID for the Application Gateway subnet. null if enable_appgw_subnet is false."
  value       = var.enable_appgw_subnet ? azurerm_network_security_group.appgw[0].id : null
  sensitive   = false
}
