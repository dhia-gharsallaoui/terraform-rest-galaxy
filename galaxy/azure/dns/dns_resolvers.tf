# ── Azure DNS Resolvers ───────────────────────────────────────────────────────

variable "azure_dns_resolvers" {
  type = map(object({
    subscription_id     = optional(string)
    resource_group_name = string
    dns_resolver_name   = optional(string, null)
    location            = optional(string, null)
    virtual_network_id  = string
    inbound_endpoints = optional(list(object({
      name                         = string
      subnet_id                    = string
      private_ip_address           = optional(string, null)
      private_ip_allocation_method = optional(string, "Dynamic")
    })), [])
    tags = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Azure Private DNS Resolvers to create via ARM REST API.
    Each resolver is attached to a virtual network and can have inbound
    endpoints for receiving DNS queries (e.g. from VPN clients).

    Inbound endpoints require a dedicated subnet (min /28) with delegation
    to Microsoft.Network/dnsResolvers.

    Example:
      azure_dns_resolvers = {
        hub = {
          resource_group_name = "ref:azure_resource_groups.launchpad.resource_group_name"
          dns_resolver_name   = "dnspr-hub-launchpad"
          virtual_network_id  = "ref:azure_virtual_networks.hub.id"
          inbound_endpoints = [
            {
              name      = "inbound"
              subnet_id = "ref:azure_virtual_networks.hub.subnet_ids.snet-dns-resolver-inbound"
            }
          ]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_dns_resolvers = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_dns_resolvers, {}), var.azure_dns_resolvers)
  )
  _dnspr_ctx = provider::rest::merge_with_outputs(local.azure_dns_resolvers, module.azure_dns_resolvers)
}

module "azure_dns_resolvers" {
  source   = "./modules/azure/dns_resolver"
  for_each = local.azure_dns_resolvers

  depends_on = [module.azure_virtual_networks]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  dns_resolver_name   = try(each.value.dns_resolver_name, null) != null ? each.value.dns_resolver_name : each.key
  location            = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  virtual_network_id  = each.value.virtual_network_id
  inbound_endpoints   = try(each.value.inbound_endpoints, [])
  tags                = try(each.value.tags, null)
  check_existance     = var.check_existance
}
