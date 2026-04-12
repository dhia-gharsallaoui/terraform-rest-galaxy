# ── Route Tables ──────────────────────────────────────────────────────────────

variable "azure_route_tables" {
  type = map(object({
    subscription_id               = string
    resource_group_name           = string
    route_table_name              = optional(string, null)
    location                      = optional(string, null)
    disable_bgp_route_propagation = optional(bool, null)
    routes = optional(list(object({
      name                = string
      address_prefix      = string
      next_hop_type       = string
      next_hop_ip_address = optional(string, null)
    })), null)
    tags = optional(map(string), null)
  }))
  description = "Map of route tables to create."
  default     = {}
}

locals {
  azure_route_tables = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_route_tables, {}), var.azure_route_tables)
  )
  _rt_ctx = provider::rest::merge_with_outputs(local.azure_route_tables, module.azure_route_tables)
}

module "azure_route_tables" {
  source   = "./modules/azure/route_table"
  for_each = local.azure_route_tables

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id               = try(each.value.subscription_id, var.subscription_id)
  resource_group_name           = each.value.resource_group_name
  route_table_name              = try(each.value.route_table_name, null) != null ? each.value.route_table_name : each.key
  location                      = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  disable_bgp_route_propagation = try(each.value.disable_bgp_route_propagation, null)
  routes                        = try(each.value.routes, null)
  tags                          = try(each.value.tags, null)
  check_existance               = var.check_existance
}
