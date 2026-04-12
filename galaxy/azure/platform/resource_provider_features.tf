# ── Resource Provider Features ────────────────────────────────────────────────

variable "azure_resource_provider_features" {
  type = map(object({
    subscription_id                  = optional(string, null)
    provider_namespace               = string
    feature_name                     = string
    state                            = optional(string, "Registered")
    metadata                         = optional(map(string), null)
    description                      = optional(string, null)
    should_feature_display_in_portal = optional(bool, null)
  }))
  description = <<-EOT
    Map of resource provider features to register on a subscription. Each map key
    acts as the for_each identifier.

    Use this to selectively enable specific provider features. When a resource
    provider is registered without specific features, all features are enabled
    by default.

    Example:
      azure_resource_provider_features = {
        encryption_at_host = {
          subscription_id    = "00000000-0000-0000-0000-000000000000"
          provider_namespace = "Microsoft.Compute"
          feature_name       = "EncryptionAtHost"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_resource_provider_features = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_resource_provider_features, {}), var.azure_resource_provider_features)
  )
  _rpf_ctx = provider::rest::merge_with_outputs(local.azure_resource_provider_features, module.azure_resource_provider_features)
}

module "azure_resource_provider_features" {
  source   = "./modules/azure/resource_provider_feature"
  for_each = local.azure_resource_provider_features

  depends_on = [module.azure_resource_provider_registrations]

  subscription_id                  = try(each.value.subscription_id, null) != null ? each.value.subscription_id : var.subscription_id
  provider_namespace               = each.value.provider_namespace
  feature_name                     = each.value.feature_name
  state                            = try(each.value.state, "Registered")
  metadata                         = try(each.value.metadata, null)
  description                      = try(each.value.description, null)
  should_feature_display_in_portal = try(each.value.should_feature_display_in_portal, null)
  check_existance                  = var.check_existance
}
