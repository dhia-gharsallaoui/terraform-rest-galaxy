# ── Subscriptions ─────────────────────────────────────────────────────────────

variable "azure_subscriptions" {
  type = map(object({
    alias_name             = optional(string, null) # null → uses the map key
    display_name           = string
    billing_scope          = string
    workload               = string
    subscription_id        = optional(string, null)
    reseller_id            = optional(string, null)
    management_group_id    = optional(string, null)
    subscription_tenant_id = optional(string, null)
    subscription_owner_id  = optional(string, null)
    tags                   = optional(map(string), null)
    _tenant                = optional(string, null)
  }))
  description = <<-EOT
    Map of subscriptions to create via subscription aliases. Each map key acts as
    the for_each identifier. When alias_name is omitted, the map key is used.

    Example:
      azure_subscriptions = {
        dev = {
          display_name  = "Development Subscription"
          billing_scope = "/billingAccounts/.../enrollmentAccounts/..."
          workload      = "DevTest"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_subscriptions = provider::rest::resolve_map(
    { externals = local._externals, remote_states = var.remote_states },
    merge(try(local._yaml_raw.azure_subscriptions, {}), var.azure_subscriptions)
  )
  _sub_ctx = provider::rest::merge_with_outputs(local.azure_subscriptions, module.azure_subscriptions)
}

module "azure_subscriptions" {
  source   = "./modules/azure/subscription"
  for_each = local.azure_subscriptions

  alias_name             = try(each.value.alias_name, null) != null ? each.value.alias_name : each.key
  display_name           = each.value.display_name
  billing_scope          = each.value.billing_scope
  workload               = each.value.workload
  subscription_id        = try(each.value.subscription_id, null)
  reseller_id            = try(each.value.reseller_id, null)
  management_group_id    = try(each.value.management_group_id, null)
  subscription_tenant_id = try(each.value.subscription_tenant_id, null)
  subscription_owner_id  = try(each.value.subscription_owner_id, null)
  tags                   = try(each.value.tags, null)
  check_existance        = var.check_existance

  # Cross-tenant: if _tenant is set, override the Authorization header
  auth_ref = try(each.value._tenant, null)
}
