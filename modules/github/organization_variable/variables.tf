# ── Scope ────────────────────────────────────────────────────────────────────

variable "organization" {
  type        = string
  description = "The GitHub organization name."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  type        = string
  description = "The name of the organization-scoped Actions variable (e.g. DEFAULT_REGION)."
}

variable "value" {
  type        = string
  description = "The value of the organization-scoped Actions variable."
}

variable "visibility" {
  type        = string
  description = "Which type of organization repositories can access the variable. One of: all, private, selected. When set to 'selected', you must also provide selected_repository_ids."

  validation {
    condition     = contains(["all", "private", "selected"], var.visibility)
    error_message = "visibility must be one of: all, private, selected."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "selected_repository_ids" {
  type        = list(number)
  default     = null
  description = "List of numeric repository IDs that can access the variable. Required (and only valid) when visibility = 'selected'."
}
