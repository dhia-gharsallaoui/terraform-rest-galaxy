# ── Billing Role Assignments ──────────────────────────────────────────────────

variable "azure_billing_role_assignments" {
  type = map(object({
    billing_account_name = string
    billing_scope        = optional(string, null)
    principal_id         = string
    principal_tenant_id  = string
    role_definition_id   = string
    principal_type       = optional(string, "ServicePrincipal")
    user_email_address   = optional(string, null)
    billing_request_id   = optional(string, null)
    _tenant              = optional(string, null)
  }))
  description = <<-EOT
    Map of billing role assignments to create. Each map key acts as the for_each
    identifier. Use this to grant billing-level roles (owner, contributor, reader)
    to identities that need access to billing accounts, profiles, or invoice sections.

    The role_definition_id can be a full path or just the GUID:
      Full:  /providers/Microsoft.Billing/billingAccounts/{name}/billingRoleDefinitions/{guid}
      GUID:  10000000-aaaa-bbbb-cccc-100000000002

    Common billing role definition names:
      - Billing account owner
      - Billing account contributor
      - Billing account reader
      - Signatory

    Example:
      azure_billing_role_assignments = {
        reader = {
          billing_account_name = "12345678-...:12345678-..._2019-05-31"
          principal_id         = "00000000-0000-0000-0000-000000000000"
          principal_tenant_id  = "00000000-0000-0000-0000-000000000000"
          role_definition_id   = "/providers/Microsoft.Billing/billingAccounts/.../billingRoleDefinitions/..."
          principal_type       = "User"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_billing_role_assignments = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_billing_role_assignments, {}), var.azure_billing_role_assignments)
  )
  _bra_ctx = provider::rest::merge_with_outputs(local.azure_billing_role_assignments, module.azure_billing_role_assignments)
}

module "azure_billing_role_assignments" {
  source   = "./modules/azure/billing_role_assignment"
  for_each = local.azure_billing_role_assignments

  depends_on = [module.azure_user_assigned_identities]

  billing_account_name = each.value.billing_account_name
  billing_scope        = try(each.value.billing_scope, null)
  principal_id         = each.value.principal_id
  principal_tenant_id  = each.value.principal_tenant_id
  role_definition_id   = each.value.role_definition_id
  principal_type       = try(each.value.principal_type, "ServicePrincipal")
  user_email_address   = try(each.value.user_email_address, null)
  billing_request_id   = try(each.value.billing_request_id, null)
  check_existance      = var.check_existance

  # Cross-tenant: if _tenant is set, override the Authorization header
  auth_ref = try(each.value._tenant, null)
}

# ── Scope owner discovery (root level to avoid module depends_on deferral) ───
# For billing role assignments pending approval, discover who owns the billing
# scope so the operator knows whom to contact.

data "rest_resource" "billing_scope_owners" {
  for_each = {
    for k, v in local.azure_billing_role_assignments : k => v
    if try(v.billing_request_id, null) != null
  }

  id = "${coalesce(
    try(each.value.billing_scope, null),
    "/providers/Microsoft.Billing/billingAccounts/${each.value.billing_account_name}"
  )}/billingRoleAssignments"

  auth_ref = try(each.value._tenant, null)

  query = {
    api-version = ["2024-04-01"]
  }
}

locals {
  # Extract owner contacts from billing scope role assignments
  _billing_scope_owners = {
    for k, ds in data.rest_resource.billing_scope_owners : k => [
      for ra in try(ds.output.value, []) :
      coalesce(
        try(ra.properties.userEmailAddress, null),
        try(ra.properties.principalId, "unknown")
      )
      if can(regex("100000000000$", try(ra.properties.roleDefinitionId, "")))
    ]
  }
}

check "billing_role_assignment_pending_approvals" {
  assert {
    condition = length(data.rest_resource.billing_scope_owners) == 0
    error_message = join("\n", flatten([
      "Billing role assignment(s) pending approval:",
      [
        for k, owners in local._billing_scope_owners :
        [
          "  ${k}:",
          "    Billing request ID : ${local.azure_billing_role_assignments[k].billing_request_id}",
          "    Scope owner(s)     : ${coalesce(join(", ", owners), "unknown — check Azure portal")}",
        ]
      ],
      [""],
      ["To approve, open the Azure portal:"],
      ["  Cost Management + Billing → Billing account → Access control (IAM) → Manage requests"],
      [""],
      ["Once approved, remove billing_request_id from the configuration and re-apply."],
    ]))
  }
}
