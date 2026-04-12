# ── Storage Account Encryption Scopes ─────────────────────────────────────────

variable "azure_storage_account_encryption_scopes" {
  type = map(object({
    subscription_id                   = optional(string, null)
    resource_group_name               = string
    account_name                      = string
    encryption_scope_name             = string
    encryption_source                 = string
    key_vault_uri                     = optional(string, null)
    key_vault_key_uri                 = optional(string, null)
    require_infrastructure_encryption = optional(bool, null)
    state                             = optional(string, "Enabled")
    check_existance                   = optional(bool, null)
  }))
  description = <<-EOT
    Map of storage account encryption scope instances to create. Each map key
    acts as the for_each identifier and must be unique within this configuration.

    Encryption scopes cannot be deleted — set state = "Disabled" to decommission.

    Example:
      azure_storage_account_encryption_scopes = {
        platform_key = {
          resource_group_name   = "rg-storage"
          account_name          = "mystorageaccount"
          encryption_scope_name = "platscope"
          encryption_source = "Microsoft.Storage"
        }
        cmk = {
          resource_group_name               = "rg-storage"
          account_name                      = "mystorageaccount"
          encryption_scope_name             = "cmkscope"
          encryption_source                 = "Microsoft.KeyVault"
          key_vault_key_uri                 = "https://myvault.vault.azure.net/keys/mykey/abc123"
          require_infrastructure_encryption = true
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_encryption_scopes = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_encryption_scopes, {}), var.azure_storage_account_encryption_scopes)
  )
}

module "azure_storage_account_encryption_scopes" {
  source   = "./modules/azure/storage_account_encryption_scope"
  for_each = local.azure_storage_account_encryption_scopes

  depends_on = [module.azure_storage_accounts]

  subscription_id                   = try(each.value.subscription_id, var.subscription_id)
  resource_group_name               = each.value.resource_group_name
  account_name                      = each.value.account_name
  encryption_scope_name             = each.value.encryption_scope_name
  encryption_source                 = each.value.encryption_source
  key_vault_uri                     = try(each.value.key_vault_uri, null)
  key_vault_key_uri                 = try(each.value.key_vault_key_uri, null)
  require_infrastructure_encryption = try(each.value.require_infrastructure_encryption, null)
  state                             = try(each.value.state, "Enabled")
  check_existance                   = try(each.value.check_existance, var.check_existance)
}
