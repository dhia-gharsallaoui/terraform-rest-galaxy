# Source: azure-rest-api-specs
#   spec_path  : billing/resource-manager/Microsoft.Billing/Billing
#   api_version: 2024-04-01
#   operation  : AssociatedTenants_CreateOrUpdate (PUT, long-running — Location header)
#   delete     : AssociatedTenants_Delete         (DELETE, long-running — Location header)

locals {
  api_version = "2024-04-01"
  path        = "/providers/Microsoft.Billing/billingAccounts/${var.billing_account_name}/associatedTenants/${var.tenant_id}"

  body = {
    properties = {
      displayName                 = var.display_name
      tenantId                    = var.tenant_id
      billingManagementState      = var.billing_management_state
      provisioningManagementState = var.provisioning_management_state
    }
  }
}

# ── Pre-check: verify caller has write permission on associatedTenants ──────
resource "rest_operation" "check_access" {
  count    = var.precheck_access ? 1 : 0
  path     = "/providers/Microsoft.Billing/billingAccounts/${var.billing_account_name}/checkAccess"
  method   = "POST"
  auth_ref = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = {
    actions = [
      "Microsoft.Billing/billingAccounts/associatedTenants/write",
      "Microsoft.Billing/billingAccounts/associatedTenants/delete",
    ]
  }
}

locals {
  # Parse the checkAccess response — array of {action, accessDecision}
  _check_access_results = var.precheck_access ? rest_operation.check_access[0].output : null

  _write_allowed = var.precheck_access ? try(
    [for r in local._check_access_results : r if r.action == "Microsoft.Billing/billingAccounts/associatedTenants/write"][0].accessDecision == "Allowed",
    false
  ) : true

  _delete_allowed = var.precheck_access ? try(
    [for r in local._check_access_results : r if r.action == "Microsoft.Billing/billingAccounts/associatedTenants/delete"][0].accessDecision == "Allowed",
    false
  ) : true
}

# ─────────────────────────────────────────────────────────────────────────────

resource "rest_resource" "billing_associated_tenant" {
  path            = local.path
  create_method   = "PUT"
  check_existance = var.check_existance
  auth_ref        = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.displayName",
    "properties.tenantId",
    "properties.billingManagementState",
    "properties.provisioningManagementState",
    "properties.provisioningBillingRequestId",
  ])

  # PUT returns 200 (synchronous success) or 201 (async, poll via Location header).
  # The response body does NOT contain provisioningState — use code-based polling.
  poll_create = {
    status_locator    = "code"
    default_delay_sec = 10
    status = {
      success = "200"
      pending = ["201", "202"]
    }
  }

  # DELETE is long-running with Location header. Returns 202 (accepted) or 204 (not found).
  poll_delete = {
    status_locator    = "code"
    default_delay_sec = 10
    status = {
      success = "200"
      pending = ["202"]
    }
  }

  # provisioningManagementState transitions from "Pending" → "Active" server-side
  # when the permission request is approved. Ignore drift on the body field.
  lifecycle {
    ignore_changes = [body]
  }

  depends_on = [rest_operation.check_access]
}

# ── Access pre-check assertions ──────────────────────────────────────────────

check "billing_write_access" {
  assert {
    condition     = local._write_allowed
    error_message = <<-EOT
      Access denied: the current caller does not have
      'Microsoft.Billing/billingAccounts/associatedTenants/write'
      on billing account '${var.billing_account_name}'.

      Required role: Billing Account Owner.
      If you have a PIM eligible assignment, activate it in the Azure portal:
        Portal → Cost Management + Billing → Access control (IAM) → Eligible assignments
    EOT
  }
}

check "billing_delete_access" {
  assert {
    condition     = local._delete_allowed
    error_message = <<-EOT
      Warning: the current caller does not have
      'Microsoft.Billing/billingAccounts/associatedTenants/delete'
      on billing account '${var.billing_account_name}'.

      Terraform destroy will fail. Consider activating your PIM eligible
      Billing Account Owner role before running destroy.
    EOT
  }
}
