# ── Resource Provider Registrations ───────────────────────────────────────────

variable "azure_resource_provider_registrations" {
  type = map(object({
    subscription_id             = optional(string, null)
    resource_provider_namespace = string
    _tenant                     = optional(string, null)
  }))
  description = <<-EOT
    Map of resource providers to register on a subscription. Each map key acts as
    the for_each identifier.

    When a provider is registered without specifying individual features, all
    features are enabled by default (standard Azure behavior). Use the
    resource_provider_features variable to selectively register specific features.

    Example:
      azure_resource_provider_registrations = {
        compute = {
          subscription_id             = "00000000-0000-0000-0000-000000000000"
          resource_provider_namespace = "Microsoft.Compute"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_resource_provider_registrations = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_resource_provider_registrations, {}), var.azure_resource_provider_registrations)
  )
  _rpr_ctx = provider::rest::merge_with_outputs(local.azure_resource_provider_registrations, module.azure_resource_provider_registrations)
}

module "azure_resource_provider_registrations" {
  source   = "./modules/azure/resource_provider_registration"
  for_each = local.azure_resource_provider_registrations

  # Provider registration must complete before any resource that depends on
  # that namespace can be created.  For destroy, Terraform automatically
  # reverses the graph: downstream modules that depend on registrations are
  # destroyed first, so unregister runs only after all consuming resources
  # are gone.
  depends_on = [
    module.azure_subscriptions,
  ]

  subscription_id             = try(each.value.subscription_id, null) != null ? each.value.subscription_id : var.subscription_id
  resource_provider_namespace = each.value.resource_provider_namespace

  # Cross-tenant: if _tenant is set, override the Authorization header
  auth_ref = try(each.value._tenant, null)
}
