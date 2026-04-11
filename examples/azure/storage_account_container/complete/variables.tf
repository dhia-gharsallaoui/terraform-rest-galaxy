# ── Authentication — Option A: OIDC (GitHub Actions CI) ──────────────────────

variable "id_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub Actions OIDC JWT. Required when access_token is not set."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "The Azure tenant ID. Required when access_token is not set."
}

variable "client_id" {
  type        = string
  default     = null
  description = "The Azure app registration client ID. Required when access_token is not set."
}

# ── Authentication — Option B: Direct token (local dev) ──────────────────────

variable "access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Direct Azure access token for local dev."
}

# ── Module inputs ─────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The storage account name."
}

variable "container_name" {
  type        = string
  description = "The blob container name (3–63 lowercase alphanumeric or hyphens, not starting/ending with hyphen)."
}

variable "public_access" {
  type        = string
  default     = "None"
  description = "Public access level. Options: None, Blob, Container."
}

variable "metadata" {
  type        = map(string)
  default     = null
  description = "Custom metadata key-value pairs for the container."
}

variable "default_encryption_scope" {
  type        = string
  default     = null
  description = "The default encryption scope for blobs in this container."
}

variable "deny_encryption_scope_override" {
  type        = bool
  default     = null
  description = "Prevent blobs from overriding the container encryption scope."
}

variable "enable_nfs_v3_all_squash" {
  type        = bool
  default     = null
  description = "Map all NFS v3 client UIDs/GIDs to anonymous. Requires NFSv3 on the account."
}

variable "enable_nfs_v3_root_squash" {
  type        = bool
  default     = null
  description = "Map NFS v3 root UID to anonymous. Requires NFSv3 on the account."
}

variable "immutable_storage_with_versioning_enabled" {
  type        = bool
  default     = null
  description = "Enable container-level WORM with versioning."
}
