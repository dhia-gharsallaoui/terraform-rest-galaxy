# ── Authentication — Option A: OIDC (GitHub Actions CI) ────────────────────────────

variable "id_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub Actions OIDC JWT (TF_VAR_id_token=$ACTIONS_ID_TOKEN_REQUEST_TOKEN). Required when access_token is not set."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "The Azure tenant ID. Required when access_token is not set."
}

variable "client_id" {
  type        = string
  default     = null
  description = "The Azure app registration client ID (federated credential). Required when access_token is not set."
}

# ── Authentication — Option B: Direct token (local dev) ─────────────────────────

variable "access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Direct Azure access token for local dev (skips OIDC exchange)."
}

# ── Module inputs ──────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "account_name" {
  type        = string
  description = "The name of the Azure AI Foundry account."
}

variable "location" {
  type        = string
  description = "The Azure region."
}

variable "sku_name" {
  type        = string
  description = "The SKU name (e.g. S0)."
}

variable "kind" {
  type        = string
  default     = "AIFoundry"
  description = "The account kind. Must be 'AIFoundry' for Foundry v2."
}

variable "identity_type" {
  type        = string
  default     = "SystemAssigned"
  description = "The managed identity type."
}

variable "identity_user_assigned_identity_ids" {
  type        = list(string)
  default     = null
  description = "User-assigned identity IDs."
}

variable "allow_project_management" {
  type        = bool
  default     = true
  description = "Enable project management as child resources."
}

variable "public_network_access" {
  type        = string
  default     = "Disabled"
  description = "Public network access: Enabled or Disabled."
}

variable "custom_sub_domain_name" {
  type        = string
  default     = null
  description = "Custom subdomain name."
}

variable "disable_local_auth" {
  type        = bool
  default     = true
  description = "Disable local API key authentication."
}

variable "network_acls_default_action" {
  type        = string
  default     = "Deny"
  description = "Default network ACL action."
}

variable "network_acls_bypass" {
  type        = string
  default     = null
  description = "Services that bypass network ACLs."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Resource tags."
}
