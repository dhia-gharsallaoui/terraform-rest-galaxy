# Source: azure-rest-api-specs
#   spec_path : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : LocalUsers_CreateOrUpdate  (PUT, synchronous)
#   delete     : LocalUsers_Delete          (DELETE, synchronous)

locals {
  api_version     = "2025-08-01"
  local_user_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/localUsers/${var.username}"

  # Map permission_scopes to ARM camelCase property names.
  permission_scopes = [
    for s in var.permission_scopes : {
      service      = s.service
      resourceName = s.resource_name
      permissions  = s.permissions
    }
  ]

  # SSH authorized keys — map to ARM property names.
  ssh_authorized_keys = var.ssh_authorized_keys != null ? [
    for k in var.ssh_authorized_keys : {
      description = k.description
      key         = k.key
    }
  ] : null

  properties = merge(
    { permissionScopes = local.permission_scopes },
    var.home_directory != null ? { homeDirectory = var.home_directory } : {},
    local.ssh_authorized_keys != null ? { sshAuthorizedKeys = local.ssh_authorized_keys } : {},
    var.has_ssh_password != null ? { hasSshPassword = var.has_ssh_password } : {},
    var.allow_acl_authorization != null ? { allowAclAuthorization = var.allow_acl_authorization } : {},
    var.group_id != null ? { groupId = var.group_id } : {},
    var.extended_groups != null ? { extendedGroups = var.extended_groups } : {},
  )

  body = {
    properties = local.properties
  }
}

resource "rest_resource" "local_user" {
  path            = local.local_user_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.hasSshKey",
    "properties.hasSshPassword",
    "properties.sid",
    "properties.userId",
    "properties.permissionScopes",
  ])

  # PUT is synchronous — no poll_create / poll_update needed.
  # DELETE is synchronous — no poll_delete needed.
}
