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
  description = "The name of the storage account."
}

# ── Identity ──────────────────────────────────────────────────────────────────

variable "table_name" {
  type        = string
  description = "The name of the table. Must be 3–63 alphanumeric characters; must begin with a letter."

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{2,62}$", var.table_name))
    error_message = "table_name must be 3–63 alphanumeric characters beginning with a letter."
  }
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "signed_identifiers" {
  type = list(object({
    id = string
    access_policy = optional(object({
      start_time  = optional(string, null)
      expiry_time = optional(string, null)
      permission  = optional(string, null)
    }), null)
  }))
  default     = null
  description = "List of stored access policies for the table. Each entry requires a unique id (up to 64 characters)."
}

# ── Provider behaviour ────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the table already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
