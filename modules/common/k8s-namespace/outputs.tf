output "resource_id" {
  description = "The Kubernetes namespace name, used as the primary resource identifier."
  value       = kubernetes_namespace.main.metadata[0].name
  sensitive   = false
}

output "resource_name" {
  description = "The Kubernetes namespace name as provisioned."
  value       = kubernetes_namespace.main.metadata[0].name
  sensitive   = false
}

output "labels" {
  description = "The full set of labels applied to the namespace, including Arxen defaults."
  value       = kubernetes_namespace.main.metadata[0].labels
  sensitive   = false
}
