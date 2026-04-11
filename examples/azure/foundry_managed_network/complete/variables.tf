# ── Authentication — Option A: OIDC (GitHub Actions CI) ────────────────────────────

variable "id_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub Actions OIDC JWT. Required when access_token is not set."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "The Azure tenant ID. Required when access_token is not set."
}

variable "client_id" {
  type        = string
  default     = null
  description = "The Azure app registration client ID. Required when access_token is not set."
}

# ── Authentication — Option B: Direct token (local dev) ─────────────────────────

variable "access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Direct Azure access token for local dev."
}

# ── Module inputs ──────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the Foundry account."
}

variable "account_name" {
  type        = string
  description = "The name of the parent Foundry account."
}

variable "location" {
  type        = string
  description = "The Azure region (must support managed virtual network preview)."
}

variable "isolation_mode" {
  type        = string
  default     = "AllowOnlyApprovedOutbound"
  description = "The managed network isolation mode: AllowInternetOutbound, AllowOnlyApprovedOutbound, or Disabled."
}

variable "managed_network_kind" {
  type        = string
  default     = "V2"
  description = "The managed network kind: V1 or V2. Cannot revert from V2 to V1."
}

variable "firewall_sku" {
  type        = string
  default     = "Standard"
  description = "The firewall SKU: Basic or Standard."
}
