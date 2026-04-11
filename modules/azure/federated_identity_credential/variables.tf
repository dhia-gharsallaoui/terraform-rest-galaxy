# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it."
}

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the user-assigned identity."
}

variable "identity_name" {
  type        = string
  description = "The name of the user-assigned managed identity."
}

variable "federated_credential_name" {
  type        = string
  description = "The name of the federated identity credential."
}

# ── Required properties ──────────────────────────────────────────────────────

variable "issuer" {
  type        = string
  description = "The URL of the OIDC issuer to trust (e.g. AKS OIDC issuer URL)."
}

variable "subject" {
  type        = string
  description = "The identifier of the external identity (e.g. system:serviceaccount:<namespace>:<sa-name>)."
}

variable "audiences" {
  type        = list(string)
  default     = ["api://AzureADTokenExchange"]
  description = "The list of audiences that can appear in the issued token."
}
