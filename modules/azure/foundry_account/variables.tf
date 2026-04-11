# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID in which the Foundry account is created."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which the Foundry account is created."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "account_name" {
  type        = string
  description = "The name of the Azure AI Foundry account (2–64 chars, alphanumeric, hyphens, underscores, dots)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{1,63}$", var.account_name))
    error_message = "account_name must be 2–64 characters, start with alphanumeric, and contain only alphanumeric, hyphens, underscores, and dots."
  }
}

variable "location" {
  type        = string
  description = "The Azure region in which to create the Foundry account."
}

variable "sku_name" {
  type        = string
  description = "The SKU name for the Foundry account. Use 'S0' for the standard pay-as-you-go tier."
}

# ── Kind & SKU ────────────────────────────────────────────────────────────────

variable "kind" {
  type        = string
  default     = "AIFoundry"
  description = "The kind of Cognitive Services account. Must be 'AIFoundry' for Azure AI Foundry v2 (the new Microsoft Foundry experience). Do NOT use 'OpenAI' or legacy kinds."

  validation {
    condition     = var.kind == "AIFoundry"
    error_message = "kind must be 'AIFoundry' for Azure AI Foundry v2. For legacy OpenAI accounts use a different module."
  }
}

variable "sku_capacity" {
  type        = number
  default     = null
  description = "Optional capacity for the SKU when the SKU supports scale out/in."

  validation {
    condition     = var.sku_capacity == null || var.sku_capacity > 0
    error_message = "sku_capacity must be a positive integer when set."
  }
}

variable "sku_tier" {
  type        = string
  default     = null
  description = "The SKU tier: Basic, Enterprise, Free, Premium, or Standard. Optional — most Foundry accounts use sku_name alone."

  validation {
    condition     = var.sku_tier == null || contains(["Basic", "Enterprise", "Free", "Premium", "Standard"], var.sku_tier)
    error_message = "sku_tier must be one of: Basic, Enterprise, Free, Premium, Standard."
  }
}

# ── Identity ─────────────────────────────────────────────────────────────────

variable "identity_type" {
  type        = string
  default     = null
  description = "The managed identity type: None, SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'. SystemAssigned is recommended for most Foundry deployments."

  validation {
    condition     = var.identity_type == null || contains(["None", "SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be one of: None, SystemAssigned, UserAssigned, 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_user_assigned_identity_ids" {
  type        = list(string)
  default     = null
  description = "List of user-assigned managed identity resource IDs. Required when identity_type is 'UserAssigned' or 'SystemAssigned, UserAssigned'."
}

# ── Network ───────────────────────────────────────────────────────────────────

variable "public_network_access" {
  type        = string
  default     = "Disabled"
  description = "Controls public network access: 'Enabled' or 'Disabled'. Defaults to 'Disabled' for SOC2 compliance. Set to 'Enabled' for development or when using managed VNet isolation instead."

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "public_network_access must be 'Enabled' or 'Disabled'."
  }
}

variable "network_acls_default_action" {
  type        = string
  default     = "Deny"
  description = "Default network ACL action when no rule matches: 'Allow' or 'Deny'. Defaults to 'Deny' for SOC2 compliance."

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "network_acls_default_action must be 'Allow' or 'Deny'."
  }
}

variable "network_acls_bypass" {
  type        = string
  default     = null
  description = "Services allowed to bypass network ACLs: 'AzureServices' or 'None'. Use 'AzureServices' to allow trusted Microsoft services."

  validation {
    condition     = var.network_acls_bypass == null || contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "network_acls_bypass must be 'AzureServices' or 'None'."
  }
}

variable "network_acls_ip_rules" {
  type        = list(string)
  default     = null
  description = "List of IPv4 CIDR ranges allowed through network ACLs (e.g. ['203.0.113.0/24']). Applied in addition to virtual network rules."
}

variable "network_acls_virtual_network_rules" {
  type = list(object({
    id                                   = string
    ignore_missing_vnet_service_endpoint = optional(bool, false)
  }))
  default     = null
  description = "List of virtual network subnet rules. Each entry requires the full subnet resource ID."
}

variable "network_injections" {
  type = list(object({
    scenario                      = string
    subnet_arm_id                 = string
    use_microsoft_managed_network = optional(bool, false)
  }))
  default     = null
  description = <<-EOT
    Network injections for AI Foundry Agent compute. Each entry injects a subnet
    into the Foundry account for the specified scenario.

    - scenario: 'agent' (Agents service) or 'none' (no injection)
    - subnet_arm_id: Full resource ID of the subnet to delegate
    - use_microsoft_managed_network: Set true to use Microsoft-managed network
      instead of injecting a customer subnet (requires AI.ManagedVnetPreview feature flag)
  EOT

  validation {
    condition = var.network_injections == null || alltrue([
      for ni in var.network_injections : contains(["agent", "none"], ni.scenario)
    ])
    error_message = "Each network_injection scenario must be 'agent' or 'none'."
  }
}

variable "restrict_outbound_network_access" {
  type        = bool
  default     = null
  description = "When true, restricts all outbound network access from the Foundry account. Use with network_acls_ip_rules or private endpoints to allow specific destinations."
}

variable "allowed_fqdn_list" {
  type        = list(string)
  default     = null
  description = "List of fully qualified domain names (FQDNs) allowed for outbound network access when restrict_outbound_network_access is true."
}

# ── Encryption (Customer-Managed Key) ─────────────────────────────────────────

variable "encryption_key_source" {
  type        = string
  default     = null
  description = <<-EOT
    Key source for encryption at rest:
    - null or 'Microsoft.CognitiveServices': Microsoft-managed keys (default, no extra cost)
    - 'Microsoft.KeyVault': Customer-managed keys (CMK) — requires encryption_key_vault_uri,
      encryption_key_name, and a user-assigned identity with Key Vault Crypto User role.
  EOT

  validation {
    condition     = var.encryption_key_source == null || contains(["Microsoft.CognitiveServices", "Microsoft.KeyVault"], var.encryption_key_source)
    error_message = "encryption_key_source must be 'Microsoft.CognitiveServices' or 'Microsoft.KeyVault'."
  }
}

variable "encryption_key_vault_uri" {
  type        = string
  default     = null
  description = "URI of the Azure Key Vault containing the customer-managed key (e.g. 'https://my-kv.vault.azure.net/'). Required when encryption_key_source is 'Microsoft.KeyVault'."
}

variable "encryption_key_name" {
  type        = string
  default     = null
  description = "Name of the encryption key in Key Vault. Required when encryption_key_source is 'Microsoft.KeyVault'."
}

variable "encryption_key_version" {
  type        = string
  default     = null
  description = "Version of the encryption key. Leave null to always use the latest key version (auto-rotation). Pin to a specific version for manual rotation control."
}

variable "encryption_identity_client_id" {
  type        = string
  default     = null
  description = "Client ID of the user-assigned managed identity used to access the Key Vault for CMK. The identity must have the 'Key Vault Crypto User' role on the vault."
}

# ── Auth & Security ───────────────────────────────────────────────────────────

variable "disable_local_auth" {
  type        = bool
  default     = true
  description = "When true, disables local authentication (API key auth) and requires Azure AD tokens. Defaults to true for SOC2 compliance. Set false only for development or legacy integrations."
}

variable "stored_completions_disabled" {
  type        = bool
  default     = null
  description = "When true, disables storing of model completions. Enable for data sovereignty or compliance requirements."
}

variable "dynamic_throttling_enabled" {
  type        = bool
  default     = null
  description = "When true, enables dynamic throttling to automatically adjust request rates based on capacity."
}

# ── Project Management ────────────────────────────────────────────────────────

variable "allow_project_management" {
  type        = bool
  default     = null
  description = "When true, enables project management as child resources (Microsoft.CognitiveServices/accounts/projects). Required to create Foundry projects under this account."
}

variable "associated_projects" {
  type        = list(string)
  default     = null
  description = "List of project names associated with this Foundry account. Projects must exist as child resources."
}

variable "default_project" {
  type        = string
  default     = null
  description = "The default project name targeted when data plane endpoints are called without an explicit project parameter."
}

# ── Custom Domain ─────────────────────────────────────────────────────────────

variable "custom_sub_domain_name" {
  type        = string
  default     = null
  description = "Custom subdomain for the Foundry account endpoint (e.g. 'my-foundry' → 'https://my-foundry.cognitiveservices.azure.com/'). Must be globally unique."
}

# ── Storage ───────────────────────────────────────────────────────────────────

variable "user_owned_storage" {
  type = list(object({
    resource_id        = string
    identity_client_id = optional(string, null)
  }))
  default     = null
  description = <<-EOT
    List of user-owned Azure Storage accounts associated with this Foundry account.
    Used for storing completions, evaluation data, and other account data.

    - resource_id: Full ARM resource ID of the storage account
    - identity_client_id: Client ID of the managed identity used to access storage
  EOT
}

# ── RAI Monitoring ────────────────────────────────────────────────────────────

variable "rai_monitor_config_storage_resource_id" {
  type        = string
  default     = null
  description = "Resource ID of the storage account used for Responsible AI (RAI) monitoring data. Required when RAI monitoring is enabled."
}

variable "rai_monitor_config_identity_client_id" {
  type        = string
  default     = null
  description = "Client ID of the managed identity used to access the RAI monitoring storage account."
}

# ── AML Workspace (Hybrid Scenarios) ─────────────────────────────────────────

variable "aml_workspace_resource_id" {
  type        = string
  default     = null
  description = "Full resource ID of a user-owned Azure Machine Learning workspace to associate. Used for hybrid AI/ML scenarios."
}

variable "aml_workspace_identity_client_id" {
  type        = string
  default     = null
  description = "Client ID of the managed identity used to access the AML workspace."
}

# ── Restore ───────────────────────────────────────────────────────────────────

variable "restore" {
  type        = bool
  default     = null
  description = "When true, restores a previously soft-deleted Foundry account with the same name. Use when recreating a deleted account to reuse the same name and endpoint."
}

# ── Tags ──────────────────────────────────────────────────────────────────────

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to the Foundry account resource."
}
