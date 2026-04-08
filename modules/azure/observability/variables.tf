variable "tenant_id" {
  type        = string
  description = "Arxen tenant identifier (internal UUID). Used for tagging and naming."
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

variable "location" {
  type        = string
  description = "Azure region to deploy resources into."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy into."
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge with default module tags."
  default     = {}
}

variable "name_override" {
  type        = string
  description = "Override the auto-generated resource name."
  default     = null
}

variable "retention_in_days" {
  type        = number
  description = "Number of days to retain logs in the workspace."
  default     = 30
  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}

variable "sku" {
  type        = string
  description = "Log Analytics Workspace SKU."
  default     = "PerGB2018"
  validation {
    condition     = contains(["PerGB2018", "CapacityReservation"], var.sku)
    error_message = "sku must be 'PerGB2018' or 'CapacityReservation'."
  }
}

variable "application_insights_enabled" {
  type        = bool
  description = "Whether to provision an Application Insights instance backed by the Log Analytics Workspace. Provides Azure Monitor metrics, distributed tracing, and live telemetry."
  default     = true
}

variable "application_insights_type" {
  type        = string
  description = "Application type for Application Insights telemetry categorization."
  default     = "web"
  validation {
    condition     = contains(["web", "other", "java", "Node.JS", "MobileCenter"], var.application_insights_type)
    error_message = "application_insights_type must be one of: web, other, java, Node.JS, MobileCenter."
  }
}
