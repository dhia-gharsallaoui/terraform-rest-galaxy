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
  description = "The name of the storage account whose file service to configure."
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
  description = "CORS rules for the file service."
}

variable "share_delete_retention_days" {
  type        = number
  default     = 7
  description = "Number of days to retain deleted file shares (1–365)."
}

variable "smb_versions" {
  type        = list(string)
  default     = ["SMB3.0", "SMB3.1.1"]
  description = "Allowed SMB protocol versions. Valid values: SMB2.1, SMB3.0, SMB3.1.1."
}

variable "smb_authentication_methods" {
  type        = list(string)
  default     = ["Kerberos"]
  description = "Allowed SMB authentication methods. Valid values: NTLMv2, Kerberos."
}

variable "smb_kerberos_ticket_encryption" {
  type        = list(string)
  default     = ["AES-256"]
  description = "Kerberos ticket encryption types. Valid values: RC4-HMAC, AES-256."
}

variable "smb_channel_encryption" {
  type        = list(string)
  default     = ["AES-128-GCM", "AES-256-GCM"]
  description = "SMB channel encryption algorithms. Valid values: AES-128-CCM, AES-128-GCM, AES-256-GCM."
}

variable "smb_multichannel_enabled" {
  type        = bool
  default     = null
  description = "Enable SMB Multichannel (Premium FileStorage only)."
}

variable "nfs_v3_enabled" {
  type        = bool
  default     = null
  description = "Enable NFS 3.0 protocol support."
}

variable "nfs_v4_1_enabled" {
  type        = bool
  default     = null
  description = "Enable NFS 4.1 protocol support."
}
