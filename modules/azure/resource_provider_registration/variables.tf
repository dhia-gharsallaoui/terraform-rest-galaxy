# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID in which to register the resource provider."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "resource_provider_namespace" {
  type        = string
  description = "The namespace of the resource provider to register (e.g. Microsoft.Compute, Microsoft.KeyVault)."
}

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}

variable "skip_deregister" {
  type        = bool
  default     = true
  description = "Skip unregistering the provider on destroy. Defaults to true because Azure often rejects unregistration when resources still exist."
}
