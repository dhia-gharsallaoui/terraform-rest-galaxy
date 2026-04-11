variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The storage account name."
}

variable "share_name" {
  type        = string
  description = "The name of the file share."
  default     = "completeshare"
}

variable "share_quota" {
  type        = number
  description = "The provisioned share size in GiB."
  default     = 512
}

variable "access_tier" {
  type        = string
  description = "Access tier for the share."
  default     = "Hot"
}

variable "enabled_protocols" {
  type        = string
  description = "Authentication protocol: SMB or NFS."
  default     = "SMB"
}

variable "root_squash" {
  type        = string
  description = "Root squash for NFS shares."
  default     = null
}

variable "metadata" {
  type        = map(string)
  description = "Custom metadata key-value pairs."
  default = {
    environment = "production"
    team        = "platform"
  }
}

variable "signed_identifiers" {
  type = list(object({
    id = string
    access_policy = optional(object({
      start_time  = optional(string, null)
      expiry_time = optional(string, null)
      permission  = optional(string, null)
    }), null)
  }))
  description = "Stored access policies."
  default = [
    {
      id = "readonly"
      access_policy = {
        start_time  = "2025-01-01T00:00:00Z"
        expiry_time = "2026-01-01T00:00:00Z"
        permission  = "r"
      }
    }
  ]
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Azure AD tenant ID. Required for OIDC auth."
}

variable "client_id" {
  type        = string
  default     = null
  description = "Service principal client ID. Required for OIDC auth."
}

variable "id_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub Actions OIDC JWT token."
}

variable "access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Pre-fetched Azure access token."
}
