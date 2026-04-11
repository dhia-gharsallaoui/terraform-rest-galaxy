# ── Storage Account File Shares ───────────────────────────────────────────────

variable "azure_storage_account_file_shares" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    share_name          = string
    share_quota         = number
    access_tier         = optional(string, null)
    enabled_protocols   = optional(string, null)
    root_squash         = optional(string, null)
    metadata            = optional(map(string), null)
    signed_identifiers = optional(list(object({
      id = string
      access_policy = optional(object({
        start_time  = optional(string, null)
        expiry_time = optional(string, null)
        permission  = optional(string, null)
      }), null)
    })), null)
    _tenant = optional(string, null)
  }))
  description = <<-EOT
    Map of file shares to create inside storage accounts.

    Example:
      azure_storage_account_file_shares = {
        data = {
          resource_group_name = "rg-myapp"
          account_name        = "stmyapp001"
          share_name          = "myshare"
          share_quota         = 100
        }
        nfs = {
          resource_group_name = "rg-myapp"
          account_name        = "stmyapp001"
          share_name          = "nfsshare"
          share_quota         = 1024
          enabled_protocols   = "NFS"
          root_squash         = "RootSquash"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_file_shares = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_file_shares, {}), var.azure_storage_account_file_shares)
  )
}

module "azure_storage_account_file_shares" {
  source   = "./modules/azure/storage_account_file_share"
  for_each = local.azure_storage_account_file_shares

  depends_on = [module.azure_storage_accounts]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  share_name          = each.value.share_name
  share_quota         = each.value.share_quota
  access_tier         = try(each.value.access_tier, null)
  enabled_protocols   = try(each.value.enabled_protocols, null)
  root_squash         = try(each.value.root_squash, null)
  metadata            = try(each.value.metadata, null)
  signed_identifiers  = try(each.value.signed_identifiers, null)
  check_existance     = var.check_existance
}
