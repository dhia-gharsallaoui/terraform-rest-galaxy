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
  description = "The storage account name for which to create the lifecycle policy."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Azure AD tenant ID. Required for OIDC token exchange in CI."
}

variable "client_id" {
  type        = string
  default     = null
  description = "The application (client) ID used for OIDC authentication."
}

variable "id_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub Actions OIDC ID token for Azure authentication."
}

variable "access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Pre-fetched Azure access token. Takes precedence over OIDC token exchange."
}
