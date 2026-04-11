# Source: azure-rest-api-specs
#   spec_path : resources/resource-manager/Microsoft.Resources/resources
#   api_version: 2025-04-01
#   operation  : ResourceGroups_CreateOrUpdate  (PUT, synchronous)
#   delete     : ResourceGroups_Delete          (DELETE, async — Retry-After honoured)

locals {
  api_version = "2025-04-01"
  rg_path     = "/subscriptions/${var.subscription_id}/resourcegroups/${var.resource_group_name}"

  # Build body with only writable, non-null properties.
  # 'properties' sub-object has no writable fields (provisioningState is read-only), so it is omitted.
  body = merge(
    { location = var.location },
    var.managed_by != null ? { managedBy = var.managed_by } : {},
    var.tags != null ? { tags = var.tags } : {},
  )
}

resource "rest_resource" "resource_group" {
  path            = local.rg_path
  create_method   = "PUT"
  check_existance = var.check_existance
  auth_ref        = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.provisioningState",
    "type",
    "tags",
  ])

  # PUT is synchronous — no poll_create / poll_update needed.

  # DELETE is long-running; ARM signals completion when the resource returns 404.
  # The provider honours the Retry-After response header automatically;
  # default_delay_sec is the fallback when the header is absent.
  poll_delete = {
    status_locator    = "code"
    default_delay_sec = 15
    status = {
      success = "404"
      pending = ["202", "200"]
    }
  }
}
