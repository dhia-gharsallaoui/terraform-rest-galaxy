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
  description = "The name of the storage account whose file service configuration to manage."
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
  description = "List of CORS rules for the file service. Each rule specifies allowed origins, methods, headers, exposed headers, and max age in seconds."
}

# ── Share Soft Delete ──────────────────────────────────────────────────────────

variable "share_delete_retention_policy" {
  type = object({
    enabled = optional(bool, true)
    days    = optional(number, 7)
  })
  default     = null
  description = "Soft delete policy for file shares. When enabled, deleted shares are retained for the specified number of days (1–365)."

  validation {
    condition = var.share_delete_retention_policy == null || (
      var.share_delete_retention_policy.days == null ||
      (var.share_delete_retention_policy.days >= 1 && var.share_delete_retention_policy.days <= 365)
    )
    error_message = "share_delete_retention_policy.days must be between 1 and 365."
  }
}

# ── SMB Protocol Settings ──────────────────────────────────────────────────────

variable "smb_versions" {
  type        = list(string)
  default     = null
  description = "Allowed SMB protocol versions. Valid values: SMB2.1, SMB3.0, SMB3.1.1."

  validation {
    condition = var.smb_versions == null || alltrue([
      for v in var.smb_versions : contains(["SMB2.1", "SMB3.0", "SMB3.1.1"], v)
    ])
    error_message = "smb_versions must be a subset of [\"SMB2.1\", \"SMB3.0\", \"SMB3.1.1\"]."
  }
}

variable "smb_authentication_methods" {
  type        = list(string)
  default     = null
  description = "Allowed SMB authentication methods. Valid values: NTLMv2, Kerberos."

  validation {
    condition = var.smb_authentication_methods == null || alltrue([
      for v in var.smb_authentication_methods : contains(["NTLMv2", "Kerberos"], v)
    ])
    error_message = "smb_authentication_methods must be a subset of [\"NTLMv2\", \"Kerberos\"]."
  }
}

variable "smb_kerberos_ticket_encryption" {
  type        = list(string)
  default     = null
  description = "Kerberos ticket encryption types allowed for SMB. Valid values: RC4-HMAC, AES-256."

  validation {
    condition = var.smb_kerberos_ticket_encryption == null || alltrue([
      for v in var.smb_kerberos_ticket_encryption : contains(["RC4-HMAC", "AES-256"], v)
    ])
    error_message = "smb_kerberos_ticket_encryption must be a subset of [\"RC4-HMAC\", \"AES-256\"]."
  }
}

variable "smb_channel_encryption" {
  type        = list(string)
  default     = null
  description = "SMB channel encryption algorithms. Valid values: AES-128-CCM, AES-128-GCM, AES-256-GCM."

  validation {
    condition = var.smb_channel_encryption == null || alltrue([
      for v in var.smb_channel_encryption : contains(["AES-128-CCM", "AES-128-GCM", "AES-256-GCM"], v)
    ])
    error_message = "smb_channel_encryption must be a subset of [\"AES-128-CCM\", \"AES-128-GCM\", \"AES-256-GCM\"]."
  }
}

variable "smb_multichannel_enabled" {
  type        = bool
  default     = null
  description = "Enable SMB Multichannel. Only supported on Premium FileStorage storage accounts."
}

# ── NFS Protocol Settings ──────────────────────────────────────────────────────

variable "nfs_v3_enabled" {
  type        = bool
  default     = null
  description = "Enable NFS 3.0 protocol support for file shares."
}

variable "nfs_v4_1_enabled" {
  type        = bool
  default     = null
  description = "Enable NFS 4.1 protocol support for file shares."
}

# ── Provider behaviour ────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the file service settings already exist before applying. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
