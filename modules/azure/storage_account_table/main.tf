# Source: azure-rest-api-specs
#   spec_path  : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : Table_Create (PUT, synchronous)
#   delete     : Table_Delete (DELETE, synchronous)

locals {
  api_version = "2025-08-01"
  table_path  = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/tableServices/default/tables/${var.table_name}"

  # signedIdentifiers — translate to ARM field names (TableSignedIdentifier / TableAccessPolicy)
  signed_identifiers = var.signed_identifiers != null ? [
    for si in var.signed_identifiers : merge(
      { id = si.id },
      si.access_policy != null ? {
        accessPolicy = {
          for k, v in {
            startTime  = try(si.access_policy.start_time, null)
            expiryTime = try(si.access_policy.expiry_time, null)
            permission = try(si.access_policy.permission, null)
          } : k => v if v != null
        }
      } : {}
    )
  ] : null

  properties = merge(
    {},
    local.signed_identifiers != null ? { signedIdentifiers = local.signed_identifiers } : {},
  )

  body = { properties = local.properties }
}

resource "rest_resource" "table" {
  path            = local.table_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.tableName",
  ])

  # Table creation is synchronous — no poll_create / poll_update needed.
  # DELETE is also synchronous — no poll_delete needed.
}
