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
  description = "Override the auto-generated PostgreSQL server name."
  default     = null
}

variable "delegated_subnet_id" {
  type        = string
  description = "Subnet ID with Microsoft.DBforPostgreSQL/flexibleServers delegation. Required — no public access is allowed."
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for the PostgreSQL flexible server (e.g., privatelink.postgres.database.azure.com)."
}

variable "administrator_login" {
  type        = string
  description = "PostgreSQL administrator username."
}

variable "administrator_password" {
  type        = string
  description = "PostgreSQL administrator password. Handle as a secret — pass via a secret manager reference, not plain text."
  sensitive   = true
}

variable "sku_name" {
  type        = string
  description = "PostgreSQL Flexible Server compute SKU (e.g., 'GP_Standard_D2s_v3', 'B_Standard_B1ms')."
  default     = "GP_Standard_D2s_v3"
}

variable "storage_mb" {
  type        = number
  description = "Storage size in megabytes for the PostgreSQL server."
  default     = 32768
  validation {
    condition     = var.storage_mb >= 32768 && var.storage_mb <= 16777216
    error_message = "storage_mb must be between 32768 (32 GB) and 16777216 (16 TB)."
  }
}

variable "postgresql_version" {
  type        = string
  description = "PostgreSQL major version (e.g., '14', '15', '16')."
  default     = "15"
  validation {
    condition     = contains(["14", "15", "16"], var.postgresql_version)
    error_message = "postgresql_version must be '14', '15', or '16'."
  }
}

variable "geo_redundant_backup_enabled" {
  type        = bool
  description = "Enable geo-redundant backups. Recommended for stage and prod environments."
  default     = false
}

variable "zone" {
  type        = string
  description = "Availability zone for the primary server ('1', '2', or '3')."
  default     = "1"
  validation {
    condition     = contains(["1", "2", "3"], var.zone)
    error_message = "zone must be '1', '2', or '3'."
  }
}

variable "entra_auth_enabled" {
  type        = bool
  description = "Enable Azure Active Directory (Entra ID) authentication alongside password auth. Recommended for production workloads using managed identities."
  default     = false
}
