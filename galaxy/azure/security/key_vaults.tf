# ── Key Vaults ────────────────────────────────────────────────────────────────

variable "azure_key_vaults" {
  type = map(object({
    subscription_id                 = string
    resource_group_name             = string
    vault_name                      = string
    location                        = optional(string, null)
    tenant_id                       = string
    sku_name                        = optional(string, "standard")
    tags                            = optional(map(string), null)
    enable_rbac_authorization       = optional(bool, true)
    enable_purge_protection         = optional(bool, null)
    enable_soft_delete              = optional(bool, true)
    soft_delete_retention_in_days   = optional(number, 90)
    enabled_for_deployment          = optional(bool, null)
    enabled_for_disk_encryption     = optional(bool, null)
    enabled_for_template_deployment = optional(bool, null)
    public_network_access           = optional(string, null)
    create_mode                     = optional(string, null)
    network_acls = optional(object({
      default_action = string
      bypass         = optional(string, "AzureServices")
      ip_rules       = optional(list(string), [])
      virtual_network_rules = optional(list(object({
        id = string
      })), [])
    }), null)
  }))
  description = <<-EOT
    Map of key vaults to create. Each map key acts as the for_each identifier.

    Example:
      azure_key_vaults = {
        cmk = {
          subscription_id           = "00000000-0000-0000-0000-000000000000"
          tenant_id                 = "00000000-0000-0000-0000-000000000000"
          resource_group_name       = "rg-myapp-prod"
          location                  = "westeurope"
          enable_rbac_authorization = true
          enable_purge_protection   = true
        }
      }
  EOT
  default     = {}
}

locals {
  azure_key_vaults = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_key_vaults, {}), var.azure_key_vaults)
  )
  _kv_ctx = provider::rest::merge_with_outputs(local.azure_key_vaults, module.azure_key_vaults)
}

module "azure_key_vaults" {
  source   = "./modules/azure/key_vault"
  for_each = local.azure_key_vaults

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id                 = try(each.value.subscription_id, var.subscription_id)
  resource_group_name             = each.value.resource_group_name
  vault_name                      = each.value.vault_name
  location                        = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  tenant_id                       = try(each.value.tenant_id, var.tenant_id)
  sku_name                        = try(each.value.sku_name, "standard")
  tags                            = try(each.value.tags, null)
  enable_rbac_authorization       = try(each.value.enable_rbac_authorization, true)
  enable_purge_protection         = try(each.value.enable_purge_protection, null)
  enable_soft_delete              = try(each.value.enable_soft_delete, true)
  soft_delete_retention_in_days   = try(each.value.soft_delete_retention_in_days, 90)
  enabled_for_deployment          = try(each.value.enabled_for_deployment, null)
  enabled_for_disk_encryption     = try(each.value.enabled_for_disk_encryption, null)
  enabled_for_template_deployment = try(each.value.enabled_for_template_deployment, null)
  public_network_access           = try(each.value.public_network_access, null)
  create_mode                     = try(each.value.create_mode, null)
  network_acls                    = try(each.value.network_acls, null)
  check_existance                 = var.check_existance
}
