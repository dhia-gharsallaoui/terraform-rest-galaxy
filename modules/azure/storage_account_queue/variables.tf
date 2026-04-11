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

variable "queue_name" {
  type        = string
  description = "The name of the queue. Must be 3–63 lowercase alphanumeric characters or hyphens; must begin and end with an alphanumeric character; no consecutive hyphens."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.queue_name)) || can(regex("^[a-z0-9]{3}$", var.queue_name))
    error_message = "queue_name must be 3–63 lowercase alphanumeric characters or hyphens, beginning and ending with an alphanumeric character."
  }
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "metadata" {
  type        = map(string)
  default     = null
  description = "A map of custom metadata key-value pairs for the queue."
}

# ── Provider behaviour ────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the queue already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
