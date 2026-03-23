output "resource_id" {
  description = "The ARM resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.id
  sensitive   = false
}

output "resource_name" {
  description = "The name of the AKS cluster as provisioned."
  value       = azurerm_kubernetes_cluster.main.name
  sensitive   = false
}

output "cluster_id" {
  # cluster_id is an ergonomic alias for resource_id.
  description = "The ARM resource ID of the AKS cluster (alias for resource_id)."
  value       = azurerm_kubernetes_cluster.main.id
  sensitive   = false
}

output "cluster_name" {
  # cluster_name is an ergonomic alias for resource_name.
  description = "The name of the AKS cluster (alias for resource_name)."
  value       = azurerm_kubernetes_cluster.main.name
  sensitive   = false
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster. Treat as a secret — do not store in plaintext."
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity federation."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
  sensitive   = false
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity. Used to assign ACR pull permissions."
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  sensitive   = false
}

output "node_resource_group" {
  description = "The name of the auto-created MC_ resource group for cluster resources."
  value       = azurerm_kubernetes_cluster.main.node_resource_group
  sensitive   = false
}
