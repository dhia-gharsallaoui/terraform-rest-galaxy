# Source: azure-rest-api-specs
#   spec_path : subscription/resource-manager/Microsoft.Subscription/Subscription
#   api_version: 2021-10-01
#   operation  : Alias_Create  (PUT, long-running — Retry-After header)
#   delete     : Alias_Delete  (DELETE, synchronous — deletes the alias, not the subscription)

locals {
  api_version = "2021-10-01"
  alias_path  = "/providers/Microsoft.Subscription/aliases/${var.alias_name}"

  additional_properties = merge(
    var.management_group_id != null ? { managementGroupId = var.management_group_id } : {},
    var.subscription_tenant_id != null ? { subscriptionTenantId = var.subscription_tenant_id } : {},
    var.subscription_owner_id != null ? { subscriptionOwnerId = var.subscription_owner_id } : {},
    var.tags != null ? { tags = var.tags } : {},
  )

  properties = merge(
    {
      displayName  = var.display_name
      billingScope = var.billing_scope
      workload     = var.workload
    },
    var.subscription_id != null ? { subscriptionId = var.subscription_id } : {},
    var.reseller_id != null ? { resellerId = var.reseller_id } : {},
    length(local.additional_properties) > 0 ? { additionalProperties = local.additional_properties } : {},
  )

  body = {
    properties = local.properties
  }
}

resource "rest_resource" "subscription" {
  path             = local.alias_path
  create_method    = "PUT"
  check_existance  = var.check_existance
  auth_ref         = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  # The body only contains properties that are returned by the GET response
  # and should be tracked in state. Create-only properties go in ephemeral_body.
  body = local.body

  output_attrs = toset([
    "properties.subscriptionId",
    "properties.provisioningState",
  ])

  # PUT is long-running; ARM returns 200/201 with provisioningState.
  poll_create = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 10
    status = {
      success = "Succeeded"
      pending = ["Accepted"]
    }
  }

  # DELETE is synchronous — deletes the alias only, not the subscription.

  lifecycle {
    # Subscription alias properties (billingScope, displayName, workload) are
    # create-only — the GET response returns a different subset than what was
    # PUT. Ignoring body changes prevents false drift from triggering updates
    # that would make subscription_id unknown and cascade forced replacements.
    ignore_changes = [body]
  }
}
