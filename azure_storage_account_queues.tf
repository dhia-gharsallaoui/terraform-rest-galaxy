# ── Storage Account Queues ────────────────────────────────────────────────────

variable "azure_storage_account_queues" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    queue_name          = string
    metadata            = optional(map(string), null)
    _tenant             = optional(string, null)
  }))
  description = <<-EOT
    Map of queues to create inside storage accounts.

    Example:
      azure_storage_account_queues = {
        events = {
          resource_group_name = "rg-myapp"
          account_name        = "stmyapp001"
          queue_name          = "events-queue"
        }
        notifications = {
          resource_group_name = "rg-myapp"
          account_name        = "stmyapp001"
          queue_name          = "notifications"
          metadata = {
            environment = "production"
          }
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_queues = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_queues, {}), var.azure_storage_account_queues)
  )
}

module "azure_storage_account_queues" {
  source   = "./modules/azure/storage_account_queue"
  for_each = local.azure_storage_account_queues

  depends_on = [module.azure_storage_accounts]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  queue_name          = each.value.queue_name
  metadata            = try(each.value.metadata, null)
  check_existance     = var.check_existance
}
