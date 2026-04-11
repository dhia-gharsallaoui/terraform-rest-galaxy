# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID in which the storage account is created."
}

# ── Parent scope ──────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the storage account."
}

# ── Identity ──────────────────────────────────────────────────────────────────

variable "account_name" {
  type        = string
  default     = null
  description = "The name of the storage account. Globally unique, 3–24 lowercase alphanumeric characters."

  validation {
    condition     = var.account_name == null || can(regex("^[a-z0-9]{3,24}$", var.account_name))
    error_message = "account_name must be 3–24 lowercase alphanumeric characters."
  }
}

# ── Required body properties ──────────────────────────────────────────────────

variable "sku_name" {
  type        = string
  description = "The SKU name. Options: Standard_LRS, Standard_GRS, Standard_RAGRS, Standard_ZRS, Premium_LRS, Premium_ZRS, Standard_GZRS, Standard_RAGZRS."

  validation {
    condition     = contains(["Standard_LRS", "Standard_GRS", "Standard_RAGRS", "Standard_ZRS", "Premium_LRS", "Premium_ZRS", "Standard_GZRS", "Standard_RAGZRS"], var.sku_name)
    error_message = "sku_name must be one of: Standard_LRS, Standard_GRS, Standard_RAGRS, Standard_ZRS, Premium_LRS, Premium_ZRS, Standard_GZRS, Standard_RAGZRS."
  }
}

variable "kind" {
  type        = string
  description = "The type of storage account. Options: Storage, StorageV2, BlobStorage, FileStorage, BlockBlobStorage."

  validation {
    condition     = contains(["Storage", "StorageV2", "BlobStorage", "FileStorage", "BlockBlobStorage"], var.kind)
    error_message = "kind must be one of: Storage, StorageV2, BlobStorage, FileStorage, BlockBlobStorage."
  }
}

variable "location" {
  type        = string
  description = "The Azure region in which the storage account is created. Cannot be changed after creation."
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to assign to the storage account (maximum 15 key-value pairs)."

  validation {
    condition     = var.tags == null || length(var.tags) <= 15
    error_message = "Storage accounts support at most 15 tags."
  }
}

variable "zones" {
  type        = list(string)
  default     = null
  description = "Pinned logical availability zones for the storage account."
}

variable "identity_type" {
  type        = string
  default     = null
  description = "The type of managed identity. Options: None, SystemAssigned, UserAssigned, SystemAssigned,UserAssigned."

  validation {
    condition     = var.identity_type == null || contains(["None", "SystemAssigned", "UserAssigned", "SystemAssigned,UserAssigned"], var.identity_type)
    error_message = "identity_type must be one of: None, SystemAssigned, UserAssigned, SystemAssigned,UserAssigned."
  }
}

variable "identity_user_assigned_identity_ids" {
  type        = list(string)
  default     = null
  description = "List of user-assigned managed identity ARM resource IDs to associate with this storage account."
}

variable "access_tier" {
  type        = string
  default     = null
  description = "Required for kind = BlobStorage. Billing access tier. Options: Hot, Cool, Cold, Premium."

  validation {
    condition     = var.access_tier == null || contains(["Hot", "Cool", "Cold", "Premium"], var.access_tier)
    error_message = "access_tier must be one of: Hot, Cool, Cold, Premium."
  }
}

variable "https_traffic_only_enabled" {
  type        = bool
  default     = true
  description = "Allow only HTTPS traffic to the storage service. Default is true."
}

variable "minimum_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "Minimum TLS version permitted on requests. Options: TLS1_0, TLS1_1, TLS1_2."

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "allow_blob_public_access" {
  type        = bool
  default     = false
  description = "Allow or disallow public access to all blobs or containers. Default is false."
}

variable "allow_shared_key_access" {
  type        = bool
  default     = null
  description = "Whether the storage account permits Shared Key authorization. Null is equivalent to true."
}

variable "is_hns_enabled" {
  type        = bool
  default     = null
  description = "Enable Hierarchical Namespace (Azure Data Lake Storage Gen2). Immutable after creation."
}

variable "public_network_access" {
  type        = string
  default     = null
  description = "Control public network access. Options: Enabled, Disabled, SecuredByPerimeter."

  validation {
    condition     = var.public_network_access == null || contains(["Enabled", "Disabled", "SecuredByPerimeter"], var.public_network_access)
    error_message = "public_network_access must be one of: Enabled, Disabled, SecuredByPerimeter."
  }
}

variable "default_to_oauth_authentication" {
  type        = bool
  default     = null
  description = "Set the default authentication to OAuth/Entra ID. Default interpretation is false."
}

variable "allow_cross_tenant_replication" {
  type        = bool
  default     = null
  description = "Allow or disallow cross-AAD-tenant object replication. Default is false for new accounts."
}

variable "network_acls" {
  type = object({
    default_action             = string
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default     = null
  description = "Network ACL rules. When set, default_action must be 'Allow' or 'Deny'."
}

# ── Encryption (CMK) ─────────────────────────────────────────────────────────

variable "encryption_key_source" {
  type        = string
  default     = null
  description = "The encryption key source. Options: Microsoft.Storage, Microsoft.Keyvault. Set to Microsoft.Keyvault for CMK."

  validation {
    condition     = var.encryption_key_source == null || contains(["Microsoft.Storage", "Microsoft.Keyvault"], var.encryption_key_source)
    error_message = "encryption_key_source must be one of: Microsoft.Storage, Microsoft.Keyvault."
  }
}

variable "encryption_key_vault_uri" {
  type        = string
  default     = null
  description = "The URI of the key vault hosting the customer-managed key."
}

variable "encryption_key_name" {
  type        = string
  default     = null
  description = "The name of the key vault key used for CMK encryption."
}

variable "encryption_key_version" {
  type        = string
  default     = null
  description = "The version of the key vault key. Omit for automatic key rotation."
}

variable "encryption_identity" {
  type        = string
  default     = null
  description = "The ARM resource ID of the user-assigned identity used to access the key vault for CMK encryption."
}

variable "encryption_require_infrastructure_encryption" {
  type        = bool
  default     = null
  description = "Enable a secondary layer of encryption with platform-managed keys."
}

# ── Extended optional properties ──────────────────────────────────────────────

variable "large_file_shares_state" {
  type        = string
  default     = null
  description = "Allow or disallow large file shares (up to 100 TiB). Options: Disabled, Enabled. Once enabled, cannot be disabled. Only supported on StorageV2 with Standard_LRS or Standard_ZRS."

  validation {
    condition     = var.large_file_shares_state == null || contains(["Disabled", "Enabled"], var.large_file_shares_state)
    error_message = "large_file_shares_state must be 'Disabled' or 'Enabled'."
  }
}

variable "routing_preference" {
  type = object({
    routing_choice              = optional(string, "MicrosoftRouting")
    publish_microsoft_endpoints = optional(bool, false)
    publish_internet_endpoints  = optional(bool, false)
  })
  default     = null
  description = "Network routing preference for traffic delivery. routingChoice: MicrosoftRouting (default) or InternetRouting. publish_microsoft_endpoints and publish_internet_endpoints enable additional endpoint types."

  validation {
    condition     = var.routing_preference == null || contains(["MicrosoftRouting", "InternetRouting"], try(var.routing_preference.routing_choice, "MicrosoftRouting"))
    error_message = "routing_preference.routing_choice must be 'MicrosoftRouting' or 'InternetRouting'."
  }
}

variable "sas_policy" {
  type = object({
    sas_expiration_period = string
    expiration_action     = optional(string, "Log")
  })
  default     = null
  description = "SAS token expiration policy. sas_expiration_period must be an ISO 8601 duration string (e.g. '00.01:00:00' for 1 hour, '7.00:00:00' for 7 days). expiration_action: Log or Block."

  validation {
    condition     = var.sas_policy == null || contains(["Log", "Block"], try(var.sas_policy.expiration_action, "Log"))
    error_message = "sas_policy.expiration_action must be 'Log' or 'Block'."
  }
}

variable "key_expiration_period_in_days" {
  type        = number
  default     = null
  description = "The period in days after which storage account access keys expire. Requires an Azure Policy assignment for enforcement."

  validation {
    condition     = var.key_expiration_period_in_days == null || (var.key_expiration_period_in_days >= 1 && var.key_expiration_period_in_days <= 365)
    error_message = "key_expiration_period_in_days must be between 1 and 365."
  }
}

variable "dns_endpoint_type" {
  type        = string
  default     = null
  description = "Storage endpoint DNS type. Options: Standard (default), AzureDnsZone (creates endpoints in a partitioned DNS zone for increased scale)."

  validation {
    condition     = var.dns_endpoint_type == null || contains(["Standard", "AzureDnsZone"], var.dns_endpoint_type)
    error_message = "dns_endpoint_type must be 'Standard' or 'AzureDnsZone'."
  }
}

variable "is_sftp_enabled" {
  type        = bool
  default     = null
  description = "Enable SFTP (SSH File Transfer Protocol) on the storage account. Requires is_hns_enabled = true and is_local_user_enabled = true."
}

variable "is_local_user_enabled" {
  type        = bool
  default     = null
  description = "Enable local user accounts for SFTP and NFS access. Required when is_sftp_enabled = true."
}

variable "is_nfs_v3_enabled" {
  type        = bool
  default     = null
  description = "Enable NFSv3 protocol support on blob storage. Immutable after creation. Requires is_hns_enabled = true and a virtual network rule."
}

variable "enable_extended_groups" {
  type        = bool
  default     = null
  description = "Enable extended group support (more than 16 groups) for local users with SFTP/NFS. Requires is_local_user_enabled = true."
}

variable "immutable_storage_with_versioning_enabled" {
  type        = bool
  default     = null
  description = "Enable account-level immutable storage (WORM) with blob versioning. Once enabled, cannot be disabled."
}

# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
