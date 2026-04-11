# ── Authentication — Option A: OIDC (GitHub Actions CI) ─────────────────────

variable "id_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "tenant_id" {
  type    = string
  default = null
}

variable "client_id" {
  type    = string
  default = null
}

# ── Authentication — Option B: Direct token (local dev) ─────────────────────

variable "access_token" {
  type      = string
  sensitive = true
  default   = null
}

# ── Module inputs ─────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the parent Foundry account."
}

variable "account_name" {
  type        = string
  description = "The parent Foundry account name."
}

variable "location" {
  type        = string
  description = "The Azure region of the Foundry account."
}

variable "deployment_name" {
  type        = string
  description = "Name for this deployment."
  default     = "gpt-4o-complete"
}
