variable "tenant_id" {
  type        = string
  description = "Arxen tenant identifier. Must be a UUID (e.g., '550e8400-e29b-41d4-a716-446655440000'). Used in resource naming (first 8 hex chars) and tagging."
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid UUID (lowercase hex, format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
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
  description = "Override the auto-generated Key Vault name."
  default     = null
}

variable "azure_ad_tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID for Key Vault access control."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the Key Vault private endpoint (from azure/vnet private_endpoints_subnet_id output)."
}

variable "vnet_id" {
  type        = string
  description = "VNet ID for the private DNS zone virtual network link (from azure/vnet vnet_id output)."
}

variable "sku_name" {
  type        = string
  description = "SKU for the Key Vault: 'standard' or 'premium'."
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be 'standard' or 'premium'."
  }
}
