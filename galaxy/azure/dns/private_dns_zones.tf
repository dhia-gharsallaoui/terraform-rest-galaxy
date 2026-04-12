# ── Private DNS Zones ─────────────────────────────────────────────────────────

variable "azure_private_dns_zones" {
  type = map(object({
    subscription_id     = optional(string)
    resource_group_name = string
    zone_name           = optional(string, null)
    tags                = optional(map(string), null)
    virtual_network_links = optional(list(object({
      name                 = string
      virtual_network_id   = string
      registration_enabled = optional(bool, false)
      resolution_policy    = optional(string)
      tags                 = optional(map(string))
    })), [])
  }))
  description = "Map of Private DNS zones to create."
  default     = {}
}

locals {
  azure_private_dns_zones = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_private_dns_zones, {}), var.azure_private_dns_zones)
  )
  _pdz_ctx = provider::rest::merge_with_outputs(local.azure_private_dns_zones, module.azure_private_dns_zones)
}

module "azure_private_dns_zones" {
  source   = "./modules/azure/private_dns_zone"
  for_each = local.azure_private_dns_zones

  depends_on = [module.azure_resource_groups, module.azure_virtual_networks]

  subscription_id       = try(each.value.subscription_id, var.subscription_id)
  resource_group_name   = each.value.resource_group_name
  zone_name             = try(each.value.zone_name, null) != null ? each.value.zone_name : each.key
  tags                  = try(each.value.tags, null)
  virtual_network_links = try(each.value.virtual_network_links, [])
  check_existance       = var.check_existance
}
