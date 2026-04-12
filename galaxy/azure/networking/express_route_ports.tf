# ── Express Route Ports ───────────────────────────────────────────────────────

variable "azure_express_route_ports" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    port_name           = optional(string, null)
    location            = optional(string, null)
    peering_location    = string
    bandwidth_in_gbps   = number
    encapsulation       = string
    billing_type        = optional(string, null)
    tags                = optional(map(string), null)
  }))
  description = <<-EOT
    Map of ExpressRoute Ports to create. Each map key acts as the for_each identifier.

    Example:
      azure_express_route_ports = {
        port1 = {
          subscription_id   = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-networking"
          location          = "israelcentral"
          peering_location  = "Tel Aviv"
          bandwidth_in_gbps = 100
          encapsulation     = "Dot1Q"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_express_route_ports = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_express_route_ports, {}), var.azure_express_route_ports)
  )
  _erp_ctx = provider::rest::merge_with_outputs(local.azure_express_route_ports, module.azure_express_route_ports)
}

module "azure_express_route_ports" {
  source   = "./modules/azure/express_route_port"
  for_each = local.azure_express_route_ports

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  port_name           = try(each.value.port_name, null) != null ? each.value.port_name : each.key
  location            = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  peering_location    = each.value.peering_location
  bandwidth_in_gbps   = each.value.bandwidth_in_gbps
  encapsulation       = each.value.encapsulation
  billing_type        = try(each.value.billing_type, null)
  tags                = try(each.value.tags, null)
  check_existance     = var.check_existance
}
