# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID in which the storage account resides."
}

# ── Parent scope ──────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The name of the storage account in which to create the encryption scope."
}

# ── Identity ──────────────────────────────────────────────────────────────────

variable "encryption_scope_name" {
  type        = string
  description = "The name of the encryption scope. Must be 3–63 characters, start and end with an alphanumeric character, and contain only alphanumerics and hyphens."

  validation {
    condition = (
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$", var.encryption_scope_name)) ||
      can(regex("^[a-zA-Z0-9]{3}$", var.encryption_scope_name))
    )
    error_message = "encryption_scope_name must be 3–63 characters, start and end with alphanumeric, and contain only alphanumerics and hyphens."
  }
}

# ── Required body properties ──────────────────────────────────────────────────

variable "encryption_source" {
  type        = string
  description = "The encryption scope source. Use 'Microsoft.Storage' for platform-managed keys or 'Microsoft.KeyVault' for customer-managed keys."

  validation {
    condition     = contains(["Microsoft.Storage", "Microsoft.KeyVault"], var.encryption_source)
    error_message = "encryption_source must be one of: Microsoft.Storage, Microsoft.KeyVault."
  }
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "key_vault_uri" {
  type        = string
  default     = null
  description = "The URI of the Key Vault. Required when source = Microsoft.KeyVault."
}

variable "key_vault_key_uri" {
  type        = string
  default     = null
  description = "The full URI of the Key Vault key, optionally including the key version. Used to set or rotate the CMK for this encryption scope."
}

variable "require_infrastructure_encryption" {
  type        = bool
  default     = null
  description = "When true, the service applies a secondary layer of encryption at the infrastructure level. Cannot be changed after creation."
}

variable "state" {
  type        = string
  default     = "Enabled"
  description = "The state of the encryption scope. 'Enabled' activates the scope; 'Disabled' deactivates it without deleting it. Use 'Disabled' to decommission the scope."

  validation {
    condition     = contains(["Enabled", "Disabled"], var.state)
    error_message = "state must be one of: Enabled, Disabled."
  }
}

# ── Import / brownfield ───────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "When true the provider performs a GET before PUT and imports the resource into state if it already exists. Use for brownfield import workflows."
}
