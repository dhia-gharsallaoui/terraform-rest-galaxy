# ── Container Registries ──────────────────────────────────────────────────────

variable "azure_container_registries" {
  type = map(object({
    subscription_id        = optional(string)
    resource_group_name    = string
    registry_name          = string
    sku_name               = optional(string, "Basic")
    location               = optional(string, null)
    tags                   = optional(map(string), null)
    admin_user_enabled     = optional(bool, false)
    public_network_access  = optional(string, null)
    anonymous_pull_enabled = optional(bool, null)
  }))
  description = <<-EOT
    Map of Azure Container Registries to create.

    Example:
      azure_container_registries = {
        arc = {
          resource_group_name = "ref:azure_resource_groups.arc.resource_group_name"
          registry_name       = "myacrforarcagents"
          sku_name            = "Basic"
          location            = "westeurope"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_container_registries = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_container_registries, {}), var.azure_container_registries)
  )
  _acr_ctx = provider::rest::merge_with_outputs(local.azure_container_registries, module.azure_container_registries)
}

module "azure_container_registries" {
  source   = "./modules/azure/container_registry"
  for_each = local.azure_container_registries

  depends_on = [module.azure_resource_provider_registrations]

  subscription_id        = try(each.value.subscription_id, var.subscription_id)
  resource_group_name    = each.value.resource_group_name
  registry_name          = each.value.registry_name
  sku_name               = try(each.value.sku_name, "Basic")
  location               = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  tags                   = try(each.value.tags, null)
  admin_user_enabled     = try(each.value.admin_user_enabled, false)
  public_network_access  = try(each.value.public_network_access, null)
  anonymous_pull_enabled = try(each.value.anonymous_pull_enabled, null)
  check_existance        = var.check_existance
}
