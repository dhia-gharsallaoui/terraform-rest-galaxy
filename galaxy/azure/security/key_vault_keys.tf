# ── Key Vault Keys ────────────────────────────────────────────────────────────

variable "azure_key_vault_keys" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    vault_name          = string
    key_name            = string
    key_type            = string
    key_size            = optional(number, null)
    curve_name          = optional(string, null)
    key_ops             = optional(list(string), null)
    tags                = optional(map(string), null)
  }))
  description = <<-EOT
    Map of key vault keys to create. Each map key acts as the for_each identifier.

    Example:
      azure_key_vault_keys = {
        cmk_sa = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-myapp-prod"
          vault_name          = "kv-myapp-prod"
          key_name            = "cmk-storage"
          key_type            = "RSA"
          key_size            = 2048
        }
      }
  EOT
  default     = {}
}

locals {
  azure_key_vault_keys = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_key_vault_keys, {}), var.azure_key_vault_keys)
  )
  _kvk_ctx = provider::rest::merge_with_outputs(local.azure_key_vault_keys, module.azure_key_vault_keys)
}

module "azure_key_vault_keys" {
  source   = "./modules/azure/key_vault_key"
  for_each = local.azure_key_vault_keys

  depends_on = [module.azure_key_vaults, module.azure_user_assigned_identities]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  vault_name          = each.value.vault_name
  key_name            = each.value.key_name
  key_type            = each.value.key_type
  key_size            = try(each.value.key_size, null)
  curve_name          = try(each.value.curve_name, null)
  key_ops             = try(each.value.key_ops, null)
  tags                = try(each.value.tags, null)
}
