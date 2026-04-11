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
