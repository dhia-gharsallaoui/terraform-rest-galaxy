# ── Provider behaviour ─────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the blob already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "account_name" {
  type        = string
  description = "The storage account name. Used to construct the data-plane base URL: https://{account_name}.blob.core.windows.net."
}

variable "container_name" {
  type        = string
  description = "The name of the blob container that holds the blob."
}

variable "blob_name" {
  type        = string
  description = "The name (path within the container) of the blob to manage."
}

# ── Required body properties ──────────────────────────────────────────────────

variable "blob_type" {
  type        = string
  default     = "BlockBlob"
  description = "The type of blob to create. Supported value for this module is 'BlockBlob'. PageBlob and AppendBlob require different PUT paths and are not supported."

  validation {
    condition     = var.blob_type == "BlockBlob"
    error_message = "Only 'BlockBlob' is supported by this module. Use Azure CLI or SDK for PageBlob / AppendBlob."
  }
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "content" {
  type        = string
  default     = null
  sensitive   = true
  description = "The text/JSON content to upload as the blob body. If null, an empty blob is created. Binary content is not supported via this module — use Azure CLI or SDK for binary blobs."
}

variable "content_type" {
  type        = string
  default     = "application/octet-stream"
  description = "MIME type for the blob, set via x-ms-blob-content-type header. Defaults to application/octet-stream. Use application/json for JSON blobs, text/plain for text files."
}

variable "metadata" {
  type        = map(string)
  default     = null
  description = "User-defined metadata for the blob. Each key is sent as an x-ms-meta-{key} header. Keys must be valid HTTP header names (alphanumeric and hyphens only)."
}

variable "access_tier" {
  type        = string
  default     = null
  description = "Blob access tier. Valid values for BlockBlob on Standard accounts: Hot, Cool, Cold, Archive. Leave null to use the storage account's default tier."

  validation {
    condition     = var.access_tier == null || contains(["Hot", "Cool", "Cold", "Archive"], var.access_tier)
    error_message = "access_tier must be one of: Hot, Cool, Cold, Archive."
  }
}

# ── Authentication ────────────────────────────────────────────────────────────

variable "auth_mode" {
  type        = string
  default     = "token"
  description = <<-EOT
    Authentication mode for the data-plane request. Supported values:
      "token" — Azure AD bearer token with scope https://storage.azure.com/.default
                (set via the provider security block or access_token variable)
      "sas"   — SAS token appended to the request as a query string

    For "token" mode, the bearer token is configured at the provider level
    (not directly in the module). For "sas" mode, supply the sas_token variable.

    Obtain a storage.azure.com-scoped token:
      az account get-access-token --resource https://storage.azure.com --query accessToken -o tsv
  EOT

  validation {
    condition     = contains(["token", "sas"], var.auth_mode)
    error_message = "auth_mode must be either 'token' or 'sas'."
  }
}

variable "sas_token" {
  type        = string
  default     = null
  sensitive   = true
  description = <<-EOT
    SAS token (without leading '?') for auth_mode = "sas". The token is appended
    to the request URL as a query string. Required when auth_mode = "sas".

    Generate a SAS token with az storage blob generate-sas or via the Azure portal.
    Example format: sv=2020-08-04&ss=b&srt=o&sp=rwd&se=...&spr=https&sig=...
  EOT
}
