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
  description = "Override the auto-generated storage account name. Must be 3-24 lowercase alphanumeric characters (no hyphens). If null, auto-generated name is used."
  default     = null
  validation {
    condition     = var.name_override == null || can(regex("^[a-z0-9]{3,24}$", var.name_override))
    error_message = "name_override must be 3-24 lowercase alphanumeric characters (no hyphens) to comply with Azure Storage Account naming rules."
  }
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the storage account private endpoint (use azure/vnet private_endpoints_subnet_id output)."
}

variable "vnet_id" {
  type        = string
  description = "VNet ID for the private DNS zone virtual network link (use azure/vnet vnet_id output)."
}

variable "account_tier" {
  type        = string
  description = "Performance tier: 'Standard' or 'Premium'."
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  type        = string
  description = "Replication type: 'LRS', 'ZRS', 'GRS', or 'GZRS'. Use GRS/GZRS for stage/prod."
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of: LRS, ZRS, GRS, GZRS, RAGRS, RAGZRS."
  }
}
