# Source: azure-rest-api-specs
#   spec_path : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : ObjectReplicationPolicies_CreateOrUpdate  (PUT, synchronous)
#   delete     : ObjectReplicationPolicies_Delete          (DELETE, synchronous)
#
# Note: On first creation use policy_id = "default". Azure auto-assigns a unique
# policy ID and returns it in the response. Subsequent updates must use the
# assigned ID (available via the policy_id output).

locals {
  api_version = "2025-08-01"
  policy_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/objectReplicationPolicies/${var.policy_id}"

  destination_account = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}"

  # Build the rules array — each rule maps to ARM camelCase properties.
  rules = [
    for r in var.rules : merge(
      {
        sourceContainer      = r.source_container
        destinationContainer = r.destination_container
      },
      r.rule_id != null ? { ruleId = r.rule_id } : {},
      (r.min_creation_time != null || length(r.prefix_match) > 0) ? {
        filters = merge(
          length(r.prefix_match) > 0 ? { prefixMatch = r.prefix_match } : {},
          r.min_creation_time != null ? { minCreationTime = r.min_creation_time } : {},
        )
      } : {},
    )
  ]

  properties = merge(
    {
      sourceAccount      = var.source_account
      destinationAccount = local.destination_account
      rules              = local.rules
    },
    var.metrics_enabled != null ? { metrics = { enabled = var.metrics_enabled } } : {},
    var.priority_replication_enabled != null ? { priorityReplication = { enabled = var.priority_replication_enabled } } : {},
    var.tags_replication_enabled != null ? { tagsReplication = { enabled = var.tags_replication_enabled } } : {},
  )

  body = {
    properties = local.properties
  }
}

resource "rest_resource" "object_replication_policy" {
  path            = local.policy_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.policyId",
    "properties.enabledTime",
    "properties.rules",
    "properties.provisioningState",
  ])

  # PUT is synchronous — no poll_create / poll_update needed.
  # DELETE is synchronous — no poll_delete needed.
}
