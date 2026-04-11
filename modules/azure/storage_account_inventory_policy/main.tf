# Source: azure-rest-api-specs
#   spec_path : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : BlobInventoryPolicies_CreateOrUpdate  (PUT, synchronous)
#   delete     : BlobInventoryPolicies_Delete          (DELETE, synchronous)
#
# The inventory policy name is always "default" — it is a singleton resource
# per storage account.

locals {
  api_version = "2025-08-01"
  policy_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/inventoryPolicies/default"

  # Build the ARM rules array from the input variable.
  # We build filters separately for Blob and Container object types and merge
  # the non-null result into each rule definition.
  # Using a helper map to avoid type inconsistencies in a single conditional expression.
  arm_rules = [
    for r in var.rules : {
      name        = r.name
      enabled     = r.enabled
      destination = r.destination
      definition = merge(
        {
          schedule     = { frequency = r.schedule }
          objectType   = r.object_type
          format       = r.format
          schemaFields = r.schema_fields
        },
        # Blob filters — always include blobTypes; add optional filter properties when set
        r.object_type == "Blob" ? {
          filters = merge(
            { blobTypes = r.blob_types },
            length(coalesce(r.prefix_match, [])) > 0 ? { prefixMatch = r.prefix_match } : {},
            length(coalesce(r.exclude_prefix, [])) > 0 ? { excludePrefix = r.exclude_prefix } : {},
            coalesce(r.include_snapshots, false) ? { includeSnapshots = true } : {},
            coalesce(r.include_blob_versions, false) ? { includeBlobVersions = true } : {},
            coalesce(r.include_deleted, false) ? { includeDeleted = true } : {},
          )
          } : merge(
          # Container filters — only prefixMatch and includeDeleted are applicable
          length(coalesce(r.prefix_match, [])) > 0 || coalesce(r.include_deleted, false) ? {
            filters = merge(
              length(coalesce(r.prefix_match, [])) > 0 ? { prefixMatch = r.prefix_match } : {},
              coalesce(r.include_deleted, false) ? { includeDeleted = true } : {},
            )
          } : {},
        ),
      )
    }
  ]

  body = {
    properties = {
      policy = {
        enabled = true
        type    = "Inventory"
        rules   = local.arm_rules
      }
    }
  }
}

resource "rest_resource" "inventory_policy" {
  path            = local.policy_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.lastModifiedTime",
    "properties.policy.rules",
  ])

  # PUT is synchronous — no poll_create / poll_update needed.
  # DELETE is synchronous — no poll_delete needed.
}
