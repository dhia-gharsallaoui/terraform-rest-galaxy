# Source: azure-rest-api-specs
#   spec_path : authorization/resource-manager/Microsoft.Authorization/Authorization
#   api_version: 2022-04-01
#   operation  : RoleAssignments_Create  (PUT, synchronous)
#   delete     : RoleAssignments_Delete  (DELETE, synchronous)

resource "random_uuid" "role_assignment_name" {}

locals {
  api_version = "2022-04-01"
  ra_path     = "${var.scope}/providers/Microsoft.Authorization/roleAssignments/${random_uuid.role_assignment_name.result}"

  # Azure returns roleDefinitionId with subscription scope. Normalise provider-
  # relative paths (/providers/...) to the full form so the body is idempotent.
  subscription_prefix = "/subscriptions/${var.subscription_id}"
  role_definition_id  = startswith(var.role_definition_id, "/providers/") ? "${local.subscription_prefix}${var.role_definition_id}" : var.role_definition_id

  properties = merge(
    {
      roleDefinitionId = local.role_definition_id
      principalId      = var.principal_id
      principalType    = var.principal_type
    },
    var.description != null ? { description = var.description } : {},
    var.condition != null ? { condition = var.condition } : {},
    var.condition_version != null ? { conditionVersion = var.condition_version } : {},
  )

  body = {
    properties = local.properties
  }
}

resource "rest_resource" "role_assignment" {
  path             = local.ra_path
  create_method    = "PUT"
  check_existance  = var.check_existance
  auth_ref         = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  # principalId is immutable — Azure rejects updates with 400
  # RoleAssignmentUpdateNotPermitted. Force destroy+create on change.
  force_new_attrs = toset([
    "properties.principalId",
  ])

  output_attrs = toset([
    "name",
    "type",
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.scope",
  ])
}
