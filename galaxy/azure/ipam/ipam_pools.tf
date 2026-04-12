# ── IPAM Pools ────────────────────────────────────────────────────────────────

variable "azure_ipam_pools" {
  type = map(object({
    subscription_id      = string
    resource_group_name  = string
    network_manager_name = string
    pool_name            = optional(string, null)
    location             = optional(string, null)
    address_prefixes     = list(string)
    description          = optional(string, null)
    display_name         = optional(string, null)
    parent_pool_name     = optional(string, null)
    tags                 = optional(map(string), null)
  }))
  description = <<-EOT
    Map of IPAM Pools to create under a Network Manager. Each map key acts as the for_each identifier.

    Example:
      azure_ipam_pools = {
        root = {
          subscription_id      = "00000000-0000-0000-0000-000000000000"
          resource_group_name  = "rg-networking"
          network_manager_name = "nm-main"
          location             = "westeurope"
          address_prefixes     = ["10.0.0.0/8"]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_ipam_pools = provider::rest::resolve_map(
    local._ctx_l0c,
    merge(try(local._yaml_raw.azure_ipam_pools, {}), var.azure_ipam_pools)
  )
  _ipam_pool_ctx = provider::rest::merge_with_outputs(local.azure_ipam_pools, module.azure_ipam_pools)
}

module "azure_ipam_pools" {
  source   = "./modules/azure/ipam_pool"
  for_each = local.azure_ipam_pools

  depends_on = [module.azure_network_managers]

  subscription_id      = try(each.value.subscription_id, var.subscription_id)
  resource_group_name  = each.value.resource_group_name
  network_manager_name = each.value.network_manager_name
  pool_name            = try(each.value.pool_name, each.key)
  location             = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  address_prefixes     = each.value.address_prefixes
  description          = try(each.value.description, null)
  display_name         = try(each.value.display_name, null)
  parent_pool_name     = try(each.value.parent_pool_name, null)
  tags                 = try(each.value.tags, null)
  check_existance      = var.check_existance
}
