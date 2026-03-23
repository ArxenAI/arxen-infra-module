variable "tenant_id" {
  type        = string
  description = "Arxen tenant identifier. Must be a UUID. Used in resource naming and tagging."
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid UUID (lowercase hex)."
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
  description = "Override the auto-generated AI workspace name."
  default     = null
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault resource ID for workspace secret storage (use azure/keyvault vault_id output)."
}

variable "storage_account_id" {
  type        = string
  description = "Storage Account resource ID for workspace artifact storage (use azure/storage account_id output)."
}

variable "container_registry_id" {
  type        = string
  description = "Container Registry resource ID for workspace Docker image management (use azure/acr registry_id output)."
}

variable "application_insights_id" {
  type        = string
  description = "Application Insights resource ID for workspace monitoring. Optional — set to null to skip."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether to enable public network access to the workspace. Must be false for production environments."
  default     = false
}

variable "image_build_compute_name" {
  type        = string
  description = "Name of the compute target for image builds. Optional."
  default     = null
}
