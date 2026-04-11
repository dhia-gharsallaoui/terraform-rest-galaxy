# ── Management Locks ──────────────────────────────────────────────────────────

variable "azure_management_locks" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    lock_name           = string
    lock_level          = optional(string, "CanNotDelete")
    notes               = optional(string, null)
    _tenant             = optional(string, null)
  }))
  description = <<-EOT
    Map of management locks to create at the resource group level.
    Use CanNotDelete locks on critical infrastructure (e.g. state storage)
    to prevent accidental deletion.

    Example:
      azure_management_locks = {
        protect_state = {
          resource_group_name = "rg-terraform-state"
          lock_name           = "protect-terraform-state"
          lock_level          = "CanNotDelete"
          notes               = "Protects Terraform state storage from accidental deletion."
        }
      }
  EOT
  default     = {}
}

locals {
  azure_management_locks = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_management_locks, {}), var.azure_management_locks)
  )
  _mlock_ctx = provider::rest::merge_with_outputs(local.azure_management_locks, module.azure_management_locks)
}

module "azure_management_locks" {
  source   = "./modules/azure/management_lock"
  for_each = local.azure_management_locks

  depends_on = [module.azure_resource_groups]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  lock_name           = each.value.lock_name
  lock_level          = try(each.value.lock_level, "CanNotDelete")
  notes               = try(each.value.notes, null)

  auth_ref = try(each.value._tenant, null)
}
