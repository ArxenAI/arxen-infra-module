variable "tenant_id" {
  type        = string
  description = "Arxen tenant identifier (internal UUID). Embedded in the label set."
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

variable "component" {
  type        = string
  description = "The name of this component (e.g., 'api', 'worker', 'frontend'). Maps to app.kubernetes.io/component."
}

variable "part_of" {
  type        = string
  description = "The application this component belongs to (e.g., 'arxen-api'). Maps to app.kubernetes.io/part-of."
}

variable "version" {
  type        = string
  description = "Semantic version of the component being deployed (e.g., '1.2.3'). Maps to app.kubernetes.io/version. Leave empty to omit."
  default     = ""
}

variable "extra_labels" {
  type        = map(string)
  description = "Additional caller-supplied labels merged with the standard set. Caller labels may not override 'app.kubernetes.io/managed-by' or 'arxen.io/*' keys."
  default     = {}
}
