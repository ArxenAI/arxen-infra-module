variable "tenant_id" {
  type        = string
  description = "Arxen tenant identifier (internal UUID). Used for tagging and naming."
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
}

variable "sku" {
  type        = string
  description = "Log Analytics Workspace SKU."
  default     = "PerGB2018"
}
