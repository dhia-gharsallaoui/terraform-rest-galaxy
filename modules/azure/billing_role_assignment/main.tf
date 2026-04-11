# Source: azure-rest-api-specs
#   spec_path  : billing/resource-manager/Microsoft.Billing/Billing
#   api_version: 2024-04-01
#
# EA billing accounts (enrollment number only):
#   create : BillingRoleAssignments_CreateOrUpdateByBillingAccount  (PUT, 201 + Location LRO)
#   delete : BillingRoleAssignments_DeleteByBillingAccount          (DELETE, synchronous)
#
# MCA billing accounts (GUID:GUID_date format):
#   create : BillingRoleAssignments_CreateByBillingAccount          (POST, 200 or 202 + Location LRO)
#   delete : BillingRoleAssignments_DeleteByBillingAccount          (DELETE, synchronous)

resource "random_uuid" "role_assignment_name" {}

locals {
  api_version = "2024-04-01"

  # MCA billing account names contain ':', EA enrollment numbers are numeric.
  is_mca = can(regex(":", var.billing_account_name))

  # Scope: use billing_scope if provided, else default to billing account.
  scope = coalesce(var.billing_scope, "/providers/Microsoft.Billing/billingAccounts/${var.billing_account_name}")

  # Invoice-section-scoped MCA assignments go through a billing request approval
  # flow — the POST creates a billingRequest, not a direct assignment.
  is_invoice_section = local.is_mca && can(regex("invoiceSections", local.scope))

  # Normalise role_definition_id: if it's just a GUID, build the full path.
  role_definition_id = startswith(var.role_definition_id, "/") ? var.role_definition_id : "/providers/Microsoft.Billing/billingAccounts/${var.billing_account_name}/billingRoleDefinitions/${var.role_definition_id}"

  properties = merge(
    {
      principalId       = var.principal_id
      principalTenantId = var.principal_tenant_id
      roleDefinitionId  = local.role_definition_id
    },
    var.user_email_address != null ? { userEmailAddress = var.user_email_address } : {},
  )

  _output_attrs = toset([
    "name",
    "type",
    "properties.principalId",
    "properties.principalTenantId",
    "properties.roleDefinitionId",
    "properties.principalType",
    "properties.scope",
    "properties.provisioningState",
  ])
}

# ── EA billing accounts (PUT) ────────────────────────────────────────────────
resource "rest_resource" "ea_role_assignment" {
  count = local.is_mca ? 0 : 1

  path            = "${local.scope}/billingRoleAssignments/${random_uuid.role_assignment_name.result}"
  create_method   = "PUT"
  check_existance = var.check_existance
  auth_ref        = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = {
    properties = local.properties
  }

  output_attrs = local._output_attrs

  # PUT returns 200 (update) or 201 (create, with Location + Retry-After headers).
  poll_create = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 10
    status = {
      success = "Succeeded"
      pending = ["New", "Pending", "Provisioning", "PendingBilling", "ConfirmedBilling", "Creating", "Created"]
    }
  }
}

# ── MCA billing accounts — direct (POST at billing account scope) ─────────────
resource "rest_resource" "mca_role_assignment" {
  count = local.is_mca && !local.is_invoice_section && var.billing_request_id == null ? 1 : 0

  path          = "${local.scope}/createBillingRoleAssignment"
  create_method = "POST"
  read_path     = "$unescape(body.id)" # Server-generated; unescape prevents %2F encoding
  auth_ref      = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  # MCA request body is flat — no properties wrapper.
  body = local.properties

  output_attrs = local._output_attrs

  # MCA billing role assignments are immutable — updates are not supported.
  # Map the GET response (properties-wrapped) back to the flat body format
  # so the provider does not detect drift and attempt a PUT update.
  read_response_template = jsonencode({
    principalId       = "$(body.properties.principalId)"
    principalTenantId = "$(body.properties.principalTenantId)"
    roleDefinitionId  = "$(body.properties.roleDefinitionId)"
  })

  # POST returns 200 (immediate success) or 202 (async — polls at read_path).
  poll_create = {
    status_locator    = "code"
    default_delay_sec = 5
    status = {
      success = "200"
      pending = ["202"]
    }
  }

  lifecycle {
    ignore_changes = [body]
  }
}

# ── MCA invoice section scope — creates a billing request (POST) ─────────────
# At invoice section scope, the POST doesn't create the assignment directly.
# It creates a billingRequest that must be approved by an invoice section owner.
# We use rest_operation since there's no resource to track until approved.
resource "rest_operation" "mca_invoice_section_role_request" {
  count = local.is_invoice_section && var.billing_request_id == null ? 1 : 0

  path     = "${local.scope}/createBillingRoleAssignment"
  method   = "POST"
  auth_ref = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.properties
}

# ── Pending approval check ───────────────────────────────────────────────────
# When billing_request_id is set, the role assignment is waiting for manual
# approval. The root-level check (azure_billing_role_assignments.tf) discovers
# the scope owners dynamically. This module-level check uses only variables
# so it always renders, even when module dependencies defer data sources.

check "pending_billing_request_approval" {
  assert {
    condition = var.billing_request_id == null
    error_message = join("\n", [
      "Billing role assignment is pending approval.",
      "  Billing request ID : ${coalesce(var.billing_request_id, "n/a")}",
      "  Scope              : ${local.scope}",
    ])
  }
}
