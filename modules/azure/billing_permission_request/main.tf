# Source: Azure portal network trace
#   api_version: 2020-11-01-privatepreview
#   operation  : PermissionRequests update (PUT)
#
# This resource automates the Global Admin approval of a billing provisioning
# request in the target tenant. The permissionRequests endpoint is the target-
# tenant counterpart of the billingRequests resource created by the associated
# tenant provisioning flow.
#
# The API does not support DELETE. On destroy, delete_method = "PUT" re-sends
# the same approval body (idempotent noop).
#
# count is gated on provisioning_billing_request_id being non-null. After
# approval, Azure clears this field from the associated tenant — count drops
# to 0 and the resource is cleanly removed from state (via the PUT noop).
# lifecycle { ignore_changes = all } prevents spurious updates while the
# resource is active.

locals {
  api_version = "2020-11-01-privatepreview"

  # Extract the GUID from /providers/Microsoft.Billing/billingRequests/<GUID>
  _parts     = var.provisioning_billing_request_id != null ? split("/", var.provisioning_billing_request_id) : []
  request_id = length(local._parts) > 0 ? element(local._parts, length(local._parts) - 1) : "none"

  path = "/providers/Microsoft.Billing/permissionRequests/${local.request_id}"
}

resource "rest_resource" "billing_permission_request" {
  count = var.provisioning_billing_request_id != null ? 1 : 0

  path             = local.path
  create_method    = "PUT"
  delete_method    = "PUT"
  auth_ref         = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = {
    properties = {
      status = var.status
    }
  }

  output_attrs = toset([
    "properties.status",
    "properties.createdDate",
    "properties.expirationDate",
    "properties.requestScope",
  ])

  poll_create = {
    status_locator    = "code"
    default_delay_sec = 5
    status = {
      success = "200"
      pending = ["202"]
    }
  }

  lifecycle {
    ignore_changes = all
  }
}

# ── GA billing request approval (2024-04-01) ────────────────────────────────
# Used for invoice-section-scoped role assignment requests that require
# approval by an invoice section owner. The billingRequests endpoint is the
# GA equivalent — works for any billing request type (role assignment,
# provisioning, etc.).
#
# Same idempotent pattern: create_method=PUT, delete_method=PUT, ignore_changes.
resource "rest_resource" "billing_request_approval" {
  count = var.billing_request_id != null ? 1 : 0

  path             = "/providers/Microsoft.Billing/billingRequests/${var.billing_request_id}"
  create_method    = "PUT"
  delete_method    = "PUT"
  auth_ref         = var.auth_ref

  query = {
    api-version = ["2024-04-01"]
  }

  body = {
    properties = {
      status = var.status
    }
  }

  output_attrs = toset([
    "properties.status",
    "properties.type",
    "properties.createdDate",
    "properties.expirationDate",
  ])

  poll_create = {
    status_locator    = "code"
    default_delay_sec = 5
    status = {
      success = "200"
      pending = ["202"]
    }
  }

  lifecycle {
    ignore_changes = all
  }
}
