variable "tenant_id" {
  type        = string
  description = "Arxen tenant identifier. Must be a UUID. Used in resource naming and tagging."
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
  description = "Azure region to deploy the AKS cluster into."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the AKS cluster into."
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge with default module tags."
  default     = {}
}

variable "name_override" {
  type        = string
  description = "Override the auto-generated AKS cluster name."
  default     = null
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where the AKS cluster will be deployed."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the AKS cluster (e.g., '1.29', '1.30')."
}

variable "node_count" {
  type        = number
  description = "Initial number of nodes in the default node pool."
  default     = 2
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "node_count must be between 1 and 100."
  }
}

variable "node_vm_size" {
  type        = string
  description = "Azure VM SKU for the default node pool (e.g., 'Standard_D4s_v5')."
  default     = "Standard_D4s_v5"
}

variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for AKS nodes (use azure/vnet aks_nodes_subnet_id output)."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace resource ID for OMS agent (use azure/observability resource_id output)."
}

variable "azure_ad_tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID for AKS RBAC integration."
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "List of Azure AD group object IDs to grant cluster admin role."
  default     = []
}

variable "disk_encryption_set_id" {
  type        = string
  description = "Resource ID of an Azure Disk Encryption Set for node OS disk CMK encryption. Required in prod environments per SPEC.md security standards. Set to null to use platform-managed keys (dev/stage only)."
  default     = null
}
