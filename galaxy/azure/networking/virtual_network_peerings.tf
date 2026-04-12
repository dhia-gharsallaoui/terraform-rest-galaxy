# ── Virtual Network Peerings ──────────────────────────────────────────────────

variable "azure_virtual_network_peerings" {
  type = map(object({
    subscription_id              = string
    resource_group_name          = string
    virtual_network_name         = string
    peering_name                 = optional(string, null)
    remote_virtual_network_id    = string
    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
  }))
  description = "Map of VNet peerings to create."
  default     = {}
}

locals {
  azure_virtual_network_peerings = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_virtual_network_peerings, {}), var.azure_virtual_network_peerings)
  )
  _vnp_ctx = provider::rest::merge_with_outputs(local.azure_virtual_network_peerings, module.azure_virtual_network_peerings)
}

module "azure_virtual_network_peerings" {
  source   = "./modules/azure/virtual_network_peering"
  for_each = local.azure_virtual_network_peerings

  depends_on = [module.azure_virtual_networks]

  subscription_id              = try(each.value.subscription_id, var.subscription_id)
  resource_group_name          = each.value.resource_group_name
  virtual_network_name         = each.value.virtual_network_name
  peering_name                 = try(each.value.peering_name, null) != null ? each.value.peering_name : each.key
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_virtual_network_access = try(each.value.allow_virtual_network_access, true)
  allow_forwarded_traffic      = try(each.value.allow_forwarded_traffic, false)
  allow_gateway_transit        = try(each.value.allow_gateway_transit, false)
  use_remote_gateways          = try(each.value.use_remote_gateways, false)
  check_existance              = var.check_existance
}
