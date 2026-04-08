variable "tenant_id" {
  type        = string
  description = "Arxen tenant identifier (internal UUID). Used in namespace labels and annotations."
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid UUID (e.g., '550e8400-e29b-41d4-a716-446655440000')."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment: 'dev', 'stage', or 'prod'."
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be 'dev', 'stage', or 'prod'."
  }
}

variable "name" {
  type        = string
  description = "Kubernetes namespace name. Must be a valid DNS label (lowercase, alphanumeric, hyphens)."
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$|^[a-z0-9]$", var.name))
    error_message = "name must be a valid DNS label: lowercase alphanumeric and hyphens, 1-63 characters, no leading/trailing hyphens."
  }
}

# In Kubernetes, labels are the equivalent of cloud resource tags.
# This variable accepts additional caller-supplied labels merged with Arxen defaults.
variable "labels" {
  type        = map(string)
  description = "Additional Kubernetes labels to merge with Arxen default labels."
  default     = {}
}

variable "deny_egress" {
  type        = bool
  description = "Whether to add a default-deny-egress NetworkPolicy. Enable for workloads that must not initiate outbound connections. Egress DNS (port 53) is always allowed when this is true."
  default     = false
}

variable "viewer_groups" {
  type        = list(string)
  description = "Kubernetes group names to bind to the built-in 'view' ClusterRole (read-only access)."
  default     = []
}

variable "editor_groups" {
  type        = list(string)
  description = "Kubernetes group names to bind to the built-in 'edit' ClusterRole (read/write access, no RBAC management)."
  default     = []
}
