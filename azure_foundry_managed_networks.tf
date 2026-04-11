# ── Azure AI Foundry Managed Networks ────────────────────────────────────────
# Microsoft.CognitiveServices/accounts/managedNetworks (child of foundry_account)
# API: 2025-10-01-preview (preview-only)
# PREREQUISITE: Feature flag AI.ManagedVnetPreview must be registered on the subscription.

variable "azure_foundry_managed_networks" {
  type = map(object({
    subscription_id      = optional(string, null)
    resource_group_name  = string
    account_name         = string
    location             = optional(string, "francecentral")
    isolation_mode       = optional(string, "AllowOnlyApprovedOutbound")
    managed_network_kind = optional(string, "V2")
    firewall_sku         = optional(string, "Standard")
    outbound_rules = optional(map(object({
      type                                 = string
      category                             = optional(string, "UserDefined")
      fqdn_destination                     = optional(string, null)
      private_endpoint_service_resource_id = optional(string, null)
      private_endpoint_subresource_target  = optional(string, null)
      private_endpoint_fqdns               = optional(list(string), null)
      service_tag                          = optional(string, null)
      service_tag_action                   = optional(string, "Allow")
      service_tag_protocol                 = optional(string, null)
      service_tag_port_ranges              = optional(string, null)
      service_tag_address_prefixes         = optional(list(string), null)
    })), null)
  }))
  description = <<-EOT
    Map of Azure AI Foundry managed networks to configure. The managed network name
    is always 'default'. Each map key acts as the for_each identifier.

    IMPORTANT: Requires the AI.ManagedVnetPreview feature flag and a supported region.
    The managed network cannot be deleted independently — it is deleted with the account.

    Example:
      azure_foundry_managed_networks = {
        main = {
          resource_group_name  = "rg-foundry"
          account_name         = "my-foundry"
          location             = "francecentral"
          isolation_mode       = "AllowOnlyApprovedOutbound"
          managed_network_kind = "V2"
          firewall_sku         = "Standard"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_foundry_managed_networks = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_foundry_managed_networks, {}), var.azure_foundry_managed_networks)
  )
  _fmn_ctx = provider::rest::merge_with_outputs(local.azure_foundry_managed_networks, module.azure_foundry_managed_networks)
}

module "azure_foundry_managed_networks" {
  source   = "./modules/azure/foundry_managed_network"
  for_each = local.azure_foundry_managed_networks

  depends_on = [module.azure_foundry_accounts]

  subscription_id      = try(each.value.subscription_id, null) != null ? each.value.subscription_id : var.subscription_id
  resource_group_name  = each.value.resource_group_name
  account_name         = each.value.account_name
  location             = try(each.value.location, "francecentral")
  isolation_mode       = try(each.value.isolation_mode, "AllowOnlyApprovedOutbound")
  managed_network_kind = try(each.value.managed_network_kind, "V2")
  firewall_sku         = try(each.value.firewall_sku, "Standard")
  outbound_rules       = try(each.value.outbound_rules, null)
}
