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
  default     = "myshare"
}

variable "share_quota" {
  type        = number
  description = "The provisioned share size in GiB."
  default     = 100
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
  description = "GitHub Actions OIDC JWT token. Set via TF_VAR_id_token=$ACTIONS_ID_TOKEN_REQUEST_TOKEN in CI."
}

variable "access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Pre-fetched Azure access token. Overrides OIDC when provided."
}
