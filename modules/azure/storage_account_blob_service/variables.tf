# ── Scope ─────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID that contains the storage account."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group that contains the storage account."
}

variable "account_name" {
  type        = string
  description = "The name of the storage account whose blob service configuration to manage."
}

# ── CORS ───────────────────────────────────────────────────────────────────────

variable "cors_rules" {
  type = list(object({
    allowed_origins    = list(string)
    allowed_methods    = list(string)
    allowed_headers    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default     = null
  description = "List of CORS rules for the blob service. Each rule specifies allowed origins, methods, headers, exposed headers, and max age in seconds."
}

# ── Soft Delete ────────────────────────────────────────────────────────────────

variable "delete_retention_policy" {
  type = object({
    enabled                = optional(bool, true)
    days                   = optional(number, 7)
    allow_permanent_delete = optional(bool, false)
  })
  default     = null
  description = "Soft delete policy for blobs. When enabled, deleted blobs are retained for the specified number of days (1–365)."

  validation {
    condition = var.delete_retention_policy == null || (
      var.delete_retention_policy.days == null ||
      (var.delete_retention_policy.days >= 1 && var.delete_retention_policy.days <= 365)
    )
    error_message = "delete_retention_policy.days must be between 1 and 365."
  }
}

variable "container_delete_retention_policy" {
  type = object({
    enabled = optional(bool, true)
    days    = optional(number, 7)
  })
  default     = null
  description = "Soft delete policy for containers. When enabled, deleted containers are retained for the specified number of days (1–365)."

  validation {
    condition = var.container_delete_retention_policy == null || (
      var.container_delete_retention_policy.days == null ||
      (var.container_delete_retention_policy.days >= 1 && var.container_delete_retention_policy.days <= 365)
    )
    error_message = "container_delete_retention_policy.days must be between 1 and 365."
  }
}

# ── Versioning ─────────────────────────────────────────────────────────────────

variable "is_versioning_enabled" {
  type        = bool
  default     = null
  description = "Enable blob versioning. When true, previous versions of blobs are automatically maintained."
}

# ── Change Feed ────────────────────────────────────────────────────────────────

variable "change_feed_enabled" {
  type        = bool
  default     = null
  description = "Enable the blob storage change feed. Provides a transaction log of all changes to blobs."
}

variable "change_feed_retention_in_days" {
  type        = number
  default     = null
  description = "The duration in days that change feed events are retained (1–146000). When null, events are retained indefinitely."

  validation {
    condition = var.change_feed_retention_in_days == null || (
      var.change_feed_retention_in_days >= 1 && var.change_feed_retention_in_days <= 146000
    )
    error_message = "change_feed_retention_in_days must be between 1 and 146000."
  }
}

# ── Point-in-Time Restore ──────────────────────────────────────────────────────

variable "restore_policy_enabled" {
  type        = bool
  default     = null
  description = "Enable point-in-time restore for block blobs. Requires soft delete, versioning, and change feed to also be enabled."
}

variable "restore_policy_days" {
  type        = number
  default     = null
  description = "How far back in days point-in-time restore can be performed (1–365). Must be less than the delete_retention_policy days."

  validation {
    condition = var.restore_policy_days == null || (
      var.restore_policy_days >= 1 && var.restore_policy_days <= 365
    )
    error_message = "restore_policy_days must be between 1 and 365."
  }
}

# ── Last Access Time Tracking ──────────────────────────────────────────────────

variable "last_access_time_tracking_enabled" {
  type        = bool
  default     = null
  description = "Enable last access time tracking policy for blobs. Used to track when blobs were last read."
}

variable "last_access_tracking_granularity_in_days" {
  type        = number
  default     = null
  description = "The granularity in days for last access time tracking. Only allowed value is 1."
}

# ── Automatic Snapshot ─────────────────────────────────────────────────────────

variable "automatic_snapshot_policy_enabled" {
  type        = bool
  default     = null
  description = "Enable automatic snapshot policy for blobs."
}

# ── Default Service Version ────────────────────────────────────────────────────

variable "default_service_version" {
  type        = string
  default     = null
  description = "The default version of the blob service to use for requests. Example: '2020-06-12'."
}

# ── Provider behaviour ────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the blob service settings already exist before applying. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
