# ── Scope ────────────────────────────────────────────────────────────────────

variable "organization" {
  type        = string
  description = "The GitHub organization name."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "secret_name" {
  type        = string
  description = "The name of the organization-scoped Actions secret (e.g. NPM_TOKEN)."
}

variable "plaintext_value" {
  type        = string
  sensitive   = true
  description = "The secret value in plain text. It will be encrypted with the organization's public key before upload."
}

variable "visibility" {
  type        = string
  description = "Which type of organization repositories have access to the secret. One of: all, private, selected. When set to 'selected', you must also provide selected_repository_ids."

  validation {
    condition     = contains(["all", "private", "selected"], var.visibility)
    error_message = "visibility must be one of: all, private, selected."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "selected_repository_ids" {
  type        = list(number)
  default     = null
  description = "List of numeric repository IDs that can access the secret. Required (and only valid) when visibility = 'selected'."
}
