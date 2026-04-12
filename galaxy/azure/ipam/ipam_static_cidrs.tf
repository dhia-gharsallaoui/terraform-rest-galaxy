# ── IPAM Static CIDRs ─────────────────────────────────────────────────────────

variable "azure_ipam_static_cidrs" {
  type = map(object({
    subscription_id                    = string
    resource_group_name                = string
    network_manager_name               = string
    pool_name                          = string
    static_cidr_name                   = optional(string, null)
    address_prefixes                   = optional(list(string), null)
    number_of_ip_addresses_to_allocate = optional(string, null)
    description                        = optional(string, null)
  }))
  description = <<-EOT
    Map of IPAM Static CIDR allocations. Each map key acts as the for_each identifier.

    Example:
      azure_ipam_static_cidrs = {
        hub1 = {
          subscription_id      = "00000000-0000-0000-0000-000000000000"
          resource_group_name  = "rg-networking"
          network_manager_name = "nm-main"
          pool_name            = "pool-hubs"
          address_prefixes     = ["10.1.0.0/24"]
          description          = "Virtual Hub 1"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_ipam_static_cidrs = provider::rest::resolve_map(
    local._ctx_l0d,
    merge(try(local._yaml_raw.azure_ipam_static_cidrs, {}), var.azure_ipam_static_cidrs)
  )
  _ipam_sc_ctx = provider::rest::merge_with_outputs(local.azure_ipam_static_cidrs, module.azure_ipam_static_cidrs)
}

module "azure_ipam_static_cidrs" {
  source   = "./modules/azure/ipam_static_cidr"
  for_each = local.azure_ipam_static_cidrs

  depends_on = [module.azure_ipam_pools]

  subscription_id                    = try(each.value.subscription_id, var.subscription_id)
  resource_group_name                = each.value.resource_group_name
  network_manager_name               = each.value.network_manager_name
  pool_name                          = each.value.pool_name
  static_cidr_name                   = try(each.value.static_cidr_name, each.key)
  address_prefixes                   = try(each.value.address_prefixes, null)
  number_of_ip_addresses_to_allocate = try(each.value.number_of_ip_addresses_to_allocate, null)
  description                        = try(each.value.description, null)
  check_existance                    = var.check_existance
}
