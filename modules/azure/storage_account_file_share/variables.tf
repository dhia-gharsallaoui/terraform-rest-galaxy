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

variable "share_name" {
  type        = string
  description = "The name of the file share. Must be 3–63 lowercase alphanumeric characters or hyphens; cannot start or end with a hyphen."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.share_name)) || can(regex("^[a-z0-9]{3}$", var.share_name))
    error_message = "share_name must be 3–63 lowercase alphanumeric characters or hyphens and cannot start/end with a hyphen."
  }
}

# ── Required body properties ──────────────────────────────────────────────────

variable "share_quota" {
  type        = number
  description = "The provisioned size of the share in gibibytes. Must be between 1 and 102400 (100 TiB). For Standard accounts: 1–102400. For Premium (FileStorage): 100–102400."

  validation {
    condition     = var.share_quota >= 1 && var.share_quota <= 102400
    error_message = "share_quota must be between 1 and 102400 GiB."
  }
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "access_tier" {
  type        = string
  default     = null
  description = "The access tier for the file share. GpV2 accounts can choose TransactionOptimized (default), Hot, or Cool. FileStorage (Premium) accounts use Premium."

  validation {
    condition     = var.access_tier == null || contains(["TransactionOptimized", "Hot", "Cool", "Premium"], var.access_tier)
    error_message = "access_tier must be one of: TransactionOptimized, Hot, Cool, Premium."
  }
}

variable "enabled_protocols" {
  type        = string
  default     = null
  description = "The authentication protocol used for the file share. Immutable after creation. Options: SMB (default), NFS (requires is_nfs_v3_enabled or is_hns_enabled on the storage account)."

  validation {
    condition     = var.enabled_protocols == null || contains(["SMB", "NFS"], var.enabled_protocols)
    error_message = "enabled_protocols must be 'SMB' or 'NFS'."
  }
}

variable "root_squash" {
  type        = string
  default     = null
  description = "Root squash behaviour for NFS shares only. Options: NoRootSquash (default), RootSquash, AllSquash."

  validation {
    condition     = var.root_squash == null || contains(["NoRootSquash", "RootSquash", "AllSquash"], var.root_squash)
    error_message = "root_squash must be one of: NoRootSquash, RootSquash, AllSquash."
  }
}

variable "metadata" {
  type        = map(string)
  default     = null
  description = "A map of custom metadata key-value pairs for the file share."
}

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
  description = "List of stored access policies for the file share. Each entry requires a unique id (up to 64 characters)."
}

# ── Provider behaviour ────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the file share already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
