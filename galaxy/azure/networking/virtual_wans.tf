# ── Virtual WANs ──────────────────────────────────────────────────────────────

variable "azure_virtual_wans" {
  type = map(object({
    subscription_id                = string
    resource_group_name            = string
    virtual_wan_name               = string
    location                       = optional(string, null)
    type                           = optional(string, "Standard")
    disable_vpn_encryption         = optional(bool, null)
    allow_branch_to_branch_traffic = optional(bool, null)
    allow_vnet_to_vnet_traffic     = optional(bool, null)
    tags                           = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Virtual WANs to create. Each map key acts as the for_each identifier.

    Example:
      azure_virtual_wans = {
        hub = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-networking"
          location            = "westeurope"
          type                = "Standard"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_virtual_wans = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_virtual_wans, {}), var.azure_virtual_wans)
  )
  _vwan_ctx = provider::rest::merge_with_outputs(local.azure_virtual_wans, module.azure_virtual_wans)
}

module "azure_virtual_wans" {
  source   = "./modules/azure/virtual_wan"
  for_each = local.azure_virtual_wans

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id                = try(each.value.subscription_id, var.subscription_id)
  resource_group_name            = each.value.resource_group_name
  virtual_wan_name               = each.value.virtual_wan_name
  location                       = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  type                           = try(each.value.type, "Standard")
  disable_vpn_encryption         = try(each.value.disable_vpn_encryption, null)
  allow_branch_to_branch_traffic = try(each.value.allow_branch_to_branch_traffic, null)
  allow_vnet_to_vnet_traffic     = try(each.value.allow_vnet_to_vnet_traffic, null)
  tags                           = try(each.value.tags, null)
  check_existance                = var.check_existance
}
