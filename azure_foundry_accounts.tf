# ── Azure AI Foundry Accounts ─────────────────────────────────────────────────
# Microsoft.CognitiveServices/accounts with kind=AIFoundry (Azure AI Foundry v2)
# API: 2025-10-01-preview (preview-only)
#
# Azure AI Foundry v2 uses Microsoft.CognitiveServices/accounts — NOT
# Microsoft.MachineLearningServices/workspaces (the old Azure AI Studio / Hub).

variable "azure_foundry_accounts" {
  type = map(object({
    # ── Scope ─────────────────────────────────────────────────────────────────
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    location            = optional(string, null)

    # ── Kind & SKU ─────────────────────────────────────────────────────────────
    kind         = optional(string, "AIFoundry")
    sku_name     = string
    sku_capacity = optional(number, null)
    sku_tier     = optional(string, null)

    # ── Identity ──────────────────────────────────────────────────────────────
    identity_type                       = optional(string, null)
    identity_user_assigned_identity_ids = optional(list(string), null)

    # ── Network ───────────────────────────────────────────────────────────────
    public_network_access       = optional(string, "Disabled")
    network_acls_default_action = optional(string, "Deny")
    network_acls_bypass         = optional(string, null)
    network_acls_ip_rules       = optional(list(string), null)
    network_acls_virtual_network_rules = optional(list(object({
      id                                   = string
      ignore_missing_vnet_service_endpoint = optional(bool, false)
    })), null)
    network_injections = optional(list(object({
      scenario                      = string
      subnet_arm_id                 = string
      use_microsoft_managed_network = optional(bool, false)
    })), null)
    restrict_outbound_network_access = optional(bool, null)
    allowed_fqdn_list                = optional(list(string), null)

    # ── Encryption (CMK) ─────────────────────────────────────────────────────
    encryption_key_source         = optional(string, null)
    encryption_key_vault_uri      = optional(string, null)
    encryption_key_name           = optional(string, null)
    encryption_key_version        = optional(string, null)
    encryption_identity_client_id = optional(string, null)

    # ── Auth & Security ───────────────────────────────────────────────────────
    disable_local_auth          = optional(bool, true)
    stored_completions_disabled = optional(bool, null)
    dynamic_throttling_enabled  = optional(bool, null)

    # ── Project Management ────────────────────────────────────────────────────
    allow_project_management = optional(bool, null)
    associated_projects      = optional(list(string), null)
    default_project          = optional(string, null)

    # ── Custom Domain ─────────────────────────────────────────────────────────
    custom_sub_domain_name = optional(string, null)

    # ── Storage ───────────────────────────────────────────────────────────────
    user_owned_storage = optional(list(object({
      resource_id        = string
      identity_client_id = optional(string, null)
    })), null)

    # ── RAI Monitoring ────────────────────────────────────────────────────────
    rai_monitor_config_storage_resource_id = optional(string, null)
    rai_monitor_config_identity_client_id  = optional(string, null)

    # ── AML Workspace ─────────────────────────────────────────────────────────
    aml_workspace_resource_id        = optional(string, null)
    aml_workspace_identity_client_id = optional(string, null)

    # ── Restore ───────────────────────────────────────────────────────────────
    restore = optional(bool, null)

    # ── Tags ──────────────────────────────────────────────────────────────────
    tags = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Azure AI Foundry accounts to create. Each map key is the for_each identifier.

    Azure AI Foundry v2 uses Microsoft.CognitiveServices/accounts with kind=AIFoundry.
    This is the NEW Foundry experience at ai.azure.com — not the old Azure AI Studio.

    Security defaults (SOC2-ready):
      - public_network_access = "Disabled"
      - disable_local_auth    = true
      - network_acls_default_action = "Deny"

    Example (minimum):
      azure_foundry_accounts = {
        main = {
          resource_group_name = "rg-foundry"
          account_name        = "my-foundry"
          location            = "francecentral"
          sku_name            = "S0"
        }
      }

    Example (with system identity and project management):
      azure_foundry_accounts = {
        main = {
          resource_group_name      = "rg-foundry"
          account_name             = "my-foundry"
          location                 = "francecentral"
          sku_name                 = "S0"
          identity_type            = "SystemAssigned"
          allow_project_management = true
          public_network_access    = "Enabled"
          disable_local_auth       = true
        }
      }

    Example (with customer-managed key):
      azure_foundry_accounts = {
        main = {
          resource_group_name           = "rg-foundry"
          account_name                  = "my-foundry"
          location                      = "francecentral"
          sku_name                      = "S0"
          identity_type                 = "UserAssigned"
          identity_user_assigned_identity_ids = ["ref:azure_user_assigned_identities.foundry.id"]
          encryption_key_source         = "Microsoft.KeyVault"
          encryption_key_vault_uri      = "ref:azure_key_vaults.foundry.vault_uri"
          encryption_key_name           = "ref:azure_key_vault_keys.foundry.name"
          encryption_identity_client_id = "ref:azure_user_assigned_identities.foundry.client_id"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_foundry_accounts = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_foundry_accounts, {}), var.azure_foundry_accounts)
  )
  _fa_ctx = provider::rest::merge_with_outputs(local.azure_foundry_accounts, module.azure_foundry_accounts)
}

module "azure_foundry_accounts" {
  source   = "./modules/azure/foundry_account"
  for_each = local.azure_foundry_accounts

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_features]

  subscription_id     = try(each.value.subscription_id, null) != null ? each.value.subscription_id : var.subscription_id
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  location            = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)

  kind         = try(each.value.kind, "AIFoundry")
  sku_name     = each.value.sku_name
  sku_capacity = try(each.value.sku_capacity, null)
  sku_tier     = try(each.value.sku_tier, null)

  identity_type                       = try(each.value.identity_type, null)
  identity_user_assigned_identity_ids = try(each.value.identity_user_assigned_identity_ids, null)

  public_network_access              = try(each.value.public_network_access, "Disabled")
  network_acls_default_action        = try(each.value.network_acls_default_action, "Deny")
  network_acls_bypass                = try(each.value.network_acls_bypass, null)
  network_acls_ip_rules              = try(each.value.network_acls_ip_rules, null)
  network_acls_virtual_network_rules = try(each.value.network_acls_virtual_network_rules, null)
  network_injections                 = try(each.value.network_injections, null)
  restrict_outbound_network_access   = try(each.value.restrict_outbound_network_access, null)
  allowed_fqdn_list                  = try(each.value.allowed_fqdn_list, null)

  encryption_key_source         = try(each.value.encryption_key_source, null)
  encryption_key_vault_uri      = try(each.value.encryption_key_vault_uri, null)
  encryption_key_name           = try(each.value.encryption_key_name, null)
  encryption_key_version        = try(each.value.encryption_key_version, null)
  encryption_identity_client_id = try(each.value.encryption_identity_client_id, null)

  disable_local_auth          = try(each.value.disable_local_auth, true)
  stored_completions_disabled = try(each.value.stored_completions_disabled, null)
  dynamic_throttling_enabled  = try(each.value.dynamic_throttling_enabled, null)

  allow_project_management = try(each.value.allow_project_management, null)
  associated_projects      = try(each.value.associated_projects, null)
  default_project          = try(each.value.default_project, null)

  custom_sub_domain_name = try(each.value.custom_sub_domain_name, null)

  user_owned_storage = try(each.value.user_owned_storage, null)

  rai_monitor_config_storage_resource_id = try(each.value.rai_monitor_config_storage_resource_id, null)
  rai_monitor_config_identity_client_id  = try(each.value.rai_monitor_config_identity_client_id, null)

  aml_workspace_resource_id        = try(each.value.aml_workspace_resource_id, null)
  aml_workspace_identity_client_id = try(each.value.aml_workspace_identity_client_id, null)

  restore = try(each.value.restore, null)
  tags    = try(each.value.tags, null)

  check_existance = var.check_existance
}
