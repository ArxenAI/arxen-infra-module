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
  description = "Override the auto-generated VNet name."
  default     = null
}

# NOTE: The CIDR defaults below are suitable for single-tenant development deployments.
# In production or multi-tenant deployments, always override these values to prevent
# address space collisions across tenants and environments.
variable "address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network."
  default     = ["10.0.0.0/16"]
}

variable "aks_nodes_cidr" {
  type        = string
  description = "CIDR for the AKS node pool subnet."
  default     = "10.0.0.0/22"
}

variable "aks_pods_cidr" {
  type        = string
  description = "CIDR for the AKS pod subnet (CNI overlay)."
  default     = "10.0.4.0/22"
}

variable "private_endpoints_cidr" {
  type        = string
  description = "CIDR for the private endpoints subnet."
  default     = "10.0.8.0/24"
}

variable "appgw_cidr" {
  type        = string
  description = "CIDR for the Application Gateway subnet."
  default     = "10.0.9.0/24"
}

variable "enable_appgw_subnet" {
  type        = bool
  description = "Whether to provision the Application Gateway subnet and NSG."
  default     = false
}
