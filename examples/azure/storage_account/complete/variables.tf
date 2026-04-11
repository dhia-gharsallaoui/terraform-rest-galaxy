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
  description = "The name of the resource group in which to create the storage account."
}

variable "account_name" {
  type        = string
  description = "The name of the storage account (globally unique, 3–24 lowercase alphanumeric)."
}

variable "sku_name" {
  type        = string
  description = "The SKU name (e.g. Standard_LRS, Standard_GRS, Premium_LRS)."
}

variable "kind" {
  type        = string
  description = "The type of storage account (e.g. StorageV2, BlobStorage, FileStorage)."
}

variable "location" {
  type        = string
  description = "The Azure region for the storage account."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to assign to the storage account."
}

variable "https_traffic_only_enabled" {
  type        = bool
  default     = true
  description = "Allow only HTTPS traffic to the storage service."
}

variable "minimum_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "Minimum TLS version (TLS1_0, TLS1_1, TLS1_2)."
}

variable "allow_blob_public_access" {
  type        = bool
  default     = false
  description = "Allow or disallow public access to all blobs or containers."
}

variable "allow_shared_key_access" {
  type        = bool
  default     = null
  description = "Whether the storage account permits Shared Key authorization."
}

variable "public_network_access" {
  type        = string
  default     = null
  description = "Control public network access (Enabled, Disabled, SecuredByPerimeter)."
}

variable "default_to_oauth_authentication" {
  type        = bool
  default     = null
  description = "Set the default authentication to OAuth/Entra ID."
}

variable "allow_cross_tenant_replication" {
  type        = bool
  default     = null
  description = "Allow or disallow cross-AAD-tenant object replication."
}

variable "large_file_shares_state" {
  type        = string
  default     = null
  description = "Allow large file shares (up to 100 TiB). Options: Disabled, Enabled."
}

variable "routing_preference" {
  type = object({
    routing_choice              = optional(string, "MicrosoftRouting")
    publish_microsoft_endpoints = optional(bool, false)
    publish_internet_endpoints  = optional(bool, false)
  })
  default     = null
  description = "Network routing preference."
}

variable "sas_policy" {
  type = object({
    sas_expiration_period = string
    expiration_action     = optional(string, "Log")
  })
  default     = null
  description = "SAS token expiration policy. sas_expiration_period is an ISO 8601 duration (e.g. '7.00:00:00')."
}

variable "key_expiration_period_in_days" {
  type        = number
  default     = null
  description = "Number of days before storage access keys expire (1–365)."
}

variable "dns_endpoint_type" {
  type        = string
  default     = null
  description = "Storage endpoint DNS type. Options: Standard, AzureDnsZone."
}

variable "is_sftp_enabled" {
  type        = bool
  default     = null
  description = "Enable SFTP support. Requires is_hns_enabled = true and is_local_user_enabled = true."
}

variable "is_local_user_enabled" {
  type        = bool
  default     = null
  description = "Enable local user accounts for SFTP/NFS."
}

variable "is_nfs_v3_enabled" {
  type        = bool
  default     = null
  description = "Enable NFSv3 protocol. Immutable after creation."
}

variable "enable_extended_groups" {
  type        = bool
  default     = null
  description = "Enable extended group support for local users."
}

variable "immutable_storage_with_versioning_enabled" {
  type        = bool
  default     = null
  description = "Enable account-level immutable storage (WORM) with versioning."
}

variable "identity_type" {
  type        = string
  default     = null
  description = "Managed identity type. Options: None, SystemAssigned, UserAssigned, SystemAssigned,UserAssigned."
}

variable "identity_user_assigned_identity_ids" {
  type        = list(string)
  default     = null
  description = "List of user-assigned managed identity ARM resource IDs."
}

variable "access_tier" {
  type        = string
  default     = null
  description = "Billing access tier. Options: Hot, Cool, Cold, Premium. Required for BlobStorage kind."
}

variable "zones" {
  type        = list(string)
  default     = null
  description = "Pinned logical availability zones."
}

variable "is_hns_enabled" {
  type        = bool
  default     = null
  description = "Enable Hierarchical Namespace (ADLS Gen2). Immutable after creation."
}

variable "network_acls" {
  type = object({
    default_action             = string
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default     = null
  description = "Network ACL rules."
}

variable "encryption_key_source" {
  type        = string
  default     = null
  description = "Encryption key source. Options: Microsoft.Storage, Microsoft.Keyvault."
}

variable "encryption_key_vault_uri" {
  type        = string
  default     = null
  description = "The URI of the key vault hosting the customer-managed key."
}

variable "encryption_key_name" {
  type        = string
  default     = null
  description = "The key vault key name for CMK."
}

variable "encryption_key_version" {
  type        = string
  default     = null
  description = "The key vault key version. Omit for auto-rotation."
}

variable "encryption_identity" {
  type        = string
  default     = null
  description = "ARM resource ID of the user-assigned identity for CMK access."
}

variable "encryption_require_infrastructure_encryption" {
  type        = bool
  default     = null
  description = "Enable double encryption with platform-managed keys."
}
