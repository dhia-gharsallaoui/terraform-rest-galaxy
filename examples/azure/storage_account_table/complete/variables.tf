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

variable "table_name" {
  type        = string
  description = "The name of the table."
  default     = "EventsTable"
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
  description = "Stored access policies for the table."
  default = [
    {
      id = "readpolicy"
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
