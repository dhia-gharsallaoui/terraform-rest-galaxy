# ── Routing Intents ───────────────────────────────────────────────────────────

variable "azure_routing_intents" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    virtual_hub_name    = string
    routing_intent_name = optional(string, "RoutingIntent")
    firewall_id         = string
    internet_traffic    = optional(bool, true)
    private_traffic     = optional(bool, true)
  }))
  description = <<-EOT
    Map of Routing Intents to create. Each map key acts as the for_each identifier.
    Routing Intent is a singleton per Virtual Hub.

    Example:
      azure_routing_intents = {
        hub = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-networking"
          virtual_hub_name    = "vhub-westeurope"
          firewall_id         = "/subscriptions/.../providers/Microsoft.Network/azureFirewalls/myFirewall"
          internet_traffic    = true
          private_traffic     = true
        }
      }
  EOT
  default     = {}
}

locals {
  azure_routing_intents = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_routing_intents, {}), var.azure_routing_intents)
  )
}

module "azure_routing_intents" {
  source   = "./modules/azure/routing_intent"
  for_each = local.azure_routing_intents

  depends_on = [module.azure_firewalls]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  virtual_hub_name    = each.value.virtual_hub_name
  routing_intent_name = try(each.value.routing_intent_name, "RoutingIntent")
  firewall_id         = each.value.firewall_id
  internet_traffic    = try(each.value.internet_traffic, true)
  private_traffic     = try(each.value.private_traffic, true)
  check_existance     = var.check_existance
}
