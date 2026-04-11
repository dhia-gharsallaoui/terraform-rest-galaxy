# Source: azure-rest-api-specs
#   spec_path  : resources/resource-manager/Microsoft.Authorization/locks
#   api_version: 2020-05-01
#   operation  : ManagementLocks_CreateOrUpdateAtResourceGroupLevel (PUT, synchronous)
#   delete     : ManagementLocks_DeleteAtResourceGroupLevel         (DELETE, synchronous)

locals {
  api_version = "2020-05-01"
  lock_path   = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Authorization/locks/${var.lock_name}"

  body = {
    properties = merge(
      { level = var.lock_level },
      var.notes != null ? { notes = var.notes } : {},
    )
  }
}

resource "rest_resource" "management_lock" {
  path             = local.lock_path
  create_method    = "PUT"
  auth_ref         = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.level",
    "properties.notes",
  ])
}
