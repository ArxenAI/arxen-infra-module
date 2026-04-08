output "resource_id" {
  description = "Not applicable — this is a utility module with no cloud resource. Always null."
  value       = null
  sensitive   = false
}

output "resource_name" {
  description = "Not applicable — this is a utility module with no cloud resource. Always null."
  value       = null
  sensitive   = false
}

output "labels" {
  description = "The full standardized Kubernetes label map. Pass this to metadata.labels on any Kubernetes resource."
  value       = local.merged
  sensitive   = false
}
