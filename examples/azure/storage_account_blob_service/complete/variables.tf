# ── Authentication — Option A: OIDC (GitHub Actions CI) ──────────────────────

variable "id_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub Actions OIDC JWT (TF_VAR_id_token=$ACTIONS_ID_TOKEN_REQUEST_TOKEN). Required when access_token is not set."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "The Azure tenant ID. Required when access_token is not set."
}

variable "client_id" {
  type        = string
  default     = null
  description = "The Azure app registration client ID (federated credential). Required when access_token is not set."
}

# ── Authentication — Option B: Direct token (local dev) ──────────────────────

variable "access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Direct Azure access token for local dev (skips OIDC exchange). Get via: source .github/scripts/get-dev-token.sh"
}

# ── Module inputs ─────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The name of the storage account whose blob service to configure."
}

variable "cors_rules" {
  type = list(object({
    allowed_origins    = list(string)
    allowed_methods    = list(string)
    allowed_headers    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default     = null
  description = "CORS rules for the blob service."
}

variable "delete_retention_days" {
  type        = number
  default     = 7
  description = "Number of days to retain deleted blobs (1–365)."
}

variable "container_delete_retention_days" {
  type        = number
  default     = 7
  description = "Number of days to retain deleted containers (1–365)."
}

variable "is_versioning_enabled" {
  type        = bool
  default     = true
  description = "Enable blob versioning."
}

variable "change_feed_enabled" {
  type        = bool
  default     = true
  description = "Enable change feed."
}

variable "change_feed_retention_in_days" {
  type        = number
  default     = 30
  description = "Change feed retention in days (1–146000)."
}

variable "restore_policy_enabled" {
  type        = bool
  default     = false
  description = "Enable point-in-time restore. Requires soft delete, versioning, and change feed."
}

variable "restore_policy_days" {
  type        = number
  default     = null
  description = "Point-in-time restore window in days (1–365). Must be less than delete_retention_days."
}

variable "last_access_time_tracking_enabled" {
  type        = bool
  default     = false
  description = "Enable last access time tracking."
}

variable "automatic_snapshot_policy_enabled" {
  type        = bool
  default     = false
  description = "Enable automatic snapshot policy."
}

variable "default_service_version" {
  type        = string
  default     = null
  description = "Default blob service version (e.g. '2020-06-12')."
}
