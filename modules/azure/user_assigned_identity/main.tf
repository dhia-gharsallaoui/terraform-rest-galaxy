# Source: azure-rest-api-specs
#   spec_path : msi/resource-manager/Microsoft.ManagedIdentity/ManagedIdentity
#   api_version: 2024-11-30
#   operation  : UserAssignedIdentities_CreateOrUpdate  (PUT, synchronous)
#   delete     : UserAssignedIdentities_Delete          (DELETE, synchronous)

locals {
  api_version = "2024-11-30"
  uai_path    = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${var.identity_name}"

  body = merge(
    { location = var.location },
    var.tags != null ? { tags = var.tags } : {},
  )
}

resource "rest_resource" "user_assigned_identity" {
  path            = local.uai_path
  create_method   = "PUT"
  check_existance = var.check_existance
  auth_ref        = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.principalId",
    "properties.clientId",
    "properties.tenantId",
  ])
}
