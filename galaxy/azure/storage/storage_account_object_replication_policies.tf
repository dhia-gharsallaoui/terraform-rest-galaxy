# ── Storage Account Object Replication Policies ───────────────────────────────

variable "azure_storage_account_object_replication_policies" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    source_account      = string
    policy_id           = optional(string, "default")
    rules = list(object({
      rule_id               = optional(string, null)
      source_container      = string
      destination_container = string
      min_creation_time     = optional(string, null)
      prefix_match          = optional(list(string), [])
    }))
    metrics_enabled              = optional(bool, null)
    priority_replication_enabled = optional(bool, null)
    tags_replication_enabled     = optional(bool, null)
  }))
  description = <<-EOT
    Map of object replication policies to create on destination storage accounts.

    Example:
      azure_storage_account_object_replication_policies = {
        prod_to_dr = {
          resource_group_name = "rg-storage-dr"
          account_name        = "stdrstorage001"          # destination account
          source_account      = "/subscriptions/.../storageAccounts/stprod001"
          rules = [
            {
              source_container      = "data"
              destination_container = "data-replica"
            }
          ]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_object_replication_policies = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_object_replication_policies, {}), var.azure_storage_account_object_replication_policies)
  )
}

module "azure_storage_account_object_replication_policies" {
  source   = "./modules/azure/storage_account_object_replication_policy"
  for_each = local.azure_storage_account_object_replication_policies

  depends_on = [module.azure_storage_accounts]

  subscription_id              = try(each.value.subscription_id, var.subscription_id)
  resource_group_name          = each.value.resource_group_name
  account_name                 = each.value.account_name
  source_account               = each.value.source_account
  policy_id                    = try(each.value.policy_id, "default")
  rules                        = each.value.rules
  metrics_enabled              = try(each.value.metrics_enabled, null)
  priority_replication_enabled = try(each.value.priority_replication_enabled, null)
  tags_replication_enabled     = try(each.value.tags_replication_enabled, null)
  check_existance              = var.check_existance
}
