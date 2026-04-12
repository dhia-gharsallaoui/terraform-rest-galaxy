# ── Network Managers ──────────────────────────────────────────────────────────

variable "azure_network_managers" {
  type = map(object({
    subscription_id         = string
    resource_group_name     = string
    network_manager_name    = optional(string, null)
    location                = optional(string, null)
    description             = optional(string, null)
    scope_subscriptions     = optional(list(string), null)
    scope_management_groups = optional(list(string), null)
    scope_accesses          = optional(list(string), null)
    tags                    = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Azure Network Managers to create. Each map key acts as the for_each identifier.

    Example:
      azure_network_managers = {
        main = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-networking"
          location            = "westeurope"
          scope_subscriptions = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_network_managers = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_network_managers, {}), var.azure_network_managers)
  )
  _nm_ctx = provider::rest::merge_with_outputs(local.azure_network_managers, module.azure_network_managers)
}

module "azure_network_managers" {
  source   = "./modules/azure/network_manager"
  for_each = local.azure_network_managers

  depends_on = [module.azure_resource_groups]

  subscription_id         = try(each.value.subscription_id, var.subscription_id)
  resource_group_name     = each.value.resource_group_name
  network_manager_name    = try(each.value.network_manager_name, each.key)
  location                = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  description             = try(each.value.description, null)
  scope_subscriptions     = try(each.value.scope_subscriptions, ["/subscriptions/${try(each.value.subscription_id, var.subscription_id)}"])
  scope_management_groups = try(each.value.scope_management_groups, null)
  scope_accesses          = try(each.value.scope_accesses, null)
  tags                    = try(each.value.tags, null)
  check_existance         = var.check_existance
}
