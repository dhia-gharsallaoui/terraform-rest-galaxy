variable "storage_access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Azure AD bearer token with scope https://storage.azure.com/.default. Obtain with: az account get-access-token --resource https://storage.azure.com --query accessToken -o tsv"
}

variable "account_name" {
  type        = string
  description = "Storage account name (used in the blob endpoint URL)."
}

variable "container_name" {
  type        = string
  description = "Blob container name."
}

variable "blob_name" {
  type        = string
  description = "Blob name (path within the container)."
}

variable "content" {
  type        = string
  sensitive   = true
  default     = null
  description = "Text/JSON content to upload as the blob body."
}

variable "content_type" {
  type        = string
  default     = "application/octet-stream"
  description = "MIME type for the blob."
}

variable "metadata" {
  type        = map(string)
  default     = null
  description = "User-defined metadata key-value pairs."
}

variable "access_tier" {
  type        = string
  default     = null
  description = "Blob access tier: Hot, Cool, Cold, or Archive."
}

variable "auth_mode" {
  type        = string
  default     = "token"
  description = "Authentication mode: 'token' or 'sas'."
}

variable "sas_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "SAS token (without leading '?') for auth_mode = 'sas'."
}

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the blob already exists before creating it."
}

# ── OIDC / CI auth (optional) ─────────────────────────────────────────────────

variable "id_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub Actions OIDC JWT for federated credential exchange."
}

variable "client_id" {
  type        = string
  default     = null
  description = "Application (client) ID for OIDC exchange."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Azure AD tenant ID for OIDC exchange."
}
