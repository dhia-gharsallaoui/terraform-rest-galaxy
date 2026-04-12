# ── Express Route Circuit Peerings ─────────────────────────────────────────────

variable "azure_express_route_circuit_peerings" {
  type = map(object({
    subscription_id               = string
    resource_group_name           = string
    circuit_name                  = string
    peering_name                  = optional(string, null)
    peering_type                  = string
    vlan_id                       = number
    peer_asn                      = optional(number, null)
    primary_peer_address_prefix   = optional(string, null)
    secondary_peer_address_prefix = optional(string, null)
    shared_key                    = optional(string, null)
    state                         = optional(string, null)
    azure_asn                     = optional(number, null)
    primary_azure_port            = optional(string, null)
    secondary_azure_port          = optional(string, null)
    gateway_manager_etag          = optional(string, null)
    route_filter_id               = optional(string, null)
  }))
  description = <<-EOT
    Map of ExpressRoute circuit peerings to create. Each map key acts as the for_each identifier.

    Example:
      azure_express_route_circuit_peerings = {
        private = {
          subscription_id               = "00000000-0000-0000-0000-000000000000"
          resource_group_name           = "rg-networking"
          circuit_name                  = "erc-israelcentral"
          peering_name                  = "AzurePrivatePeering"
          peering_type                  = "AzurePrivatePeering"
          vlan_id                       = 100
          peer_asn                      = 65515
          primary_peer_address_prefix   = "10.0.0.0/30"
          secondary_peer_address_prefix = "10.0.0.4/30"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_express_route_circuit_peerings = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_express_route_circuit_peerings, {}), var.azure_express_route_circuit_peerings)
  )
  _ercp_ctx = provider::rest::merge_with_outputs(local.azure_express_route_circuit_peerings, module.azure_express_route_circuit_peerings)
}

module "azure_express_route_circuit_peerings" {
  source   = "./modules/azure/express_route_circuit_peering"
  for_each = local.azure_express_route_circuit_peerings

  depends_on = [module.azure_express_route_circuits]

  subscription_id               = try(each.value.subscription_id, var.subscription_id)
  resource_group_name           = each.value.resource_group_name
  circuit_name                  = each.value.circuit_name
  peering_name                  = try(each.value.peering_name, null) != null ? each.value.peering_name : each.key
  peering_type                  = each.value.peering_type
  vlan_id                       = each.value.vlan_id
  peer_asn                      = try(each.value.peer_asn, null)
  primary_peer_address_prefix   = try(each.value.primary_peer_address_prefix, null)
  secondary_peer_address_prefix = try(each.value.secondary_peer_address_prefix, null)
  shared_key                    = try(each.value.shared_key, null)
  state                         = try(each.value.state, null)
  azure_asn                     = try(each.value.azure_asn, null)
  primary_azure_port            = try(each.value.primary_azure_port, null)
  secondary_azure_port          = try(each.value.secondary_azure_port, null)
  gateway_manager_etag          = try(each.value.gateway_manager_etag, null)
  route_filter_id               = try(each.value.route_filter_id, null)
  check_existance               = var.check_existance
}
