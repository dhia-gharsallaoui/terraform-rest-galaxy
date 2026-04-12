# ── Storage Account Local Users ───────────────────────────────────────────────

variable "azure_storage_account_local_users" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    account_name        = string
    username            = string
    permission_scopes = list(object({
      service       = string
      resource_name = string
      permissions   = string
    }))
    home_directory = optional(string, null)
    ssh_authorized_keys = optional(list(object({
      description = string
      key         = string
    })), null)
    has_ssh_password        = optional(bool, null)
    allow_acl_authorization = optional(bool, null)
    group_id                = optional(number, null)
    extended_groups         = optional(list(number), null)
    check_existance         = optional(bool, false)
  }))
  description = <<-EOT
    Map of Storage Account Local User instances to create. Each map key acts as the
    for_each identifier and must be unique within this configuration.
    Local users provide SFTP and NFSv3 identity for Azure Blob Storage and Azure Files.
    The parent storage account must have is_hns_enabled, is_sftp_enabled, and
    is_local_user_enabled set to true.

    Example:
      azure_storage_account_local_users = {
        sftp_upload = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-data"
          account_name        = "mydatalake"
          username            = "sftp-upload"
          permission_scopes = [
            {
              service       = "blob"
              resource_name = "uploads"
              permissions   = "rwdl"
            }
          ]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_local_users = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_local_users, {}), var.azure_storage_account_local_users)
  )
}

module "azure_storage_account_local_users" {
  source   = "./modules/azure/storage_account_local_user"
  for_each = local.azure_storage_account_local_users

  depends_on = [module.azure_storage_accounts]

  subscription_id         = try(each.value.subscription_id, var.subscription_id)
  resource_group_name     = each.value.resource_group_name
  account_name            = each.value.account_name
  username                = each.value.username
  permission_scopes       = each.value.permission_scopes
  home_directory          = try(each.value.home_directory, null)
  ssh_authorized_keys     = try(each.value.ssh_authorized_keys, null)
  has_ssh_password        = try(each.value.has_ssh_password, null)
  allow_acl_authorization = try(each.value.allow_acl_authorization, null)
  group_id                = try(each.value.group_id, null)
  extended_groups         = try(each.value.extended_groups, null)
  check_existance         = try(each.value.check_existance, var.check_existance)
}
