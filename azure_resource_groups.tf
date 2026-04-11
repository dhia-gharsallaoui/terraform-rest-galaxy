# ── Resource Groups ───────────────────────────────────────────────────────────

variable "azure_resource_groups" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    location            = optional(string, null) # null → resolved from var.default_location
    managed_by          = optional(string, null)
    tags                = optional(map(string), null)
    _tenant             = optional(string, null)
  }))
  description = <<-EOT
    Map of resource groups to create or manage. Each map key acts as the for_each
    identifier and must be unique within this configuration.

    Example:
      azure_resource_groups = {
        networking = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          # location omitted → resolved from var.default_location
          tags = {
            environment = "production"
            team        = "networking"
          }
        }
        compute = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-compute-prod"  # explicit override
          location            = "eastus"
          managed_by          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/management-rg"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_resource_groups = provider::rest::resolve_map(
    local._ctx_l0,
    merge(try(local._yaml_raw.azure_resource_groups, {}), var.azure_resource_groups)
  )
  _rg_ctx = provider::rest::merge_with_outputs(local.azure_resource_groups, module.azure_resource_groups)
}

module "azure_resource_groups" {
  source   = "./modules/azure/resource_group"
  for_each = local.azure_resource_groups

  depends_on = [module.azure_subscriptions]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = try(each.value.resource_group_name, each.key)
  location            = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  managed_by          = try(each.value.managed_by, null)
  tags                = try(each.value.tags, null)
  check_existance     = var.check_existance

  # Cross-tenant: if _tenant is set, override the Authorization header
  auth_ref = try(each.value._tenant, null)
}
