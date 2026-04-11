# ── Billing Associated Tenants ────────────────────────────────────────────────

variable "azure_billing_associated_tenants" {
  type = map(object({
    billing_account_name          = string
    tenant_id                     = string
    display_name                  = string
    billing_management_state      = optional(string, "Active")
    provisioning_management_state = optional(string, "NotRequested")
    precheck_access               = optional(bool, null) # null → inherits from var.precheck_billing_access
    _tenant                       = optional(string, null)
  }))
  description = <<-EOT
    Map of associated billing tenants to create or manage. Each map key acts as
    the for_each identifier and must be unique within this configuration.

    Requires a Microsoft Customer Agreement – Enterprise billing account.

    Example:
      azure_billing_associated_tenants = {
        partner = {
          billing_account_name          = "12345678:12345678-1234-1234-1234-123456789012_2024-01-01"
          tenant_id                     = "aaaabbbb-cccc-dddd-eeee-ffffgggggggg"
          display_name                  = "Partner Tenant"
          billing_management_state      = "Active"
          provisioning_management_state = "Pending"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_billing_associated_tenants = provider::rest::resolve_map(
    { externals = local._externals, remote_states = var.remote_states },
    merge(try(local._yaml_raw.azure_billing_associated_tenants, {}), var.azure_billing_associated_tenants)
  )
  _bat_ctx = provider::rest::merge_with_outputs(local.azure_billing_associated_tenants, module.azure_billing_associated_tenants)
}

module "azure_billing_associated_tenants" {
  source   = "./modules/azure/billing_associated_tenant"
  for_each = local.azure_billing_associated_tenants

  billing_account_name          = each.value.billing_account_name
  tenant_id                     = each.value.tenant_id
  display_name                  = each.value.display_name
  billing_management_state      = try(each.value.billing_management_state, "Active")
  provisioning_management_state = try(each.value.provisioning_management_state, "NotRequested")
  precheck_access               = coalesce(try(each.value.precheck_access, null), var.precheck_billing_access)
  check_existance               = var.check_existance

  # Cross-tenant: if _tenant is set, override the Authorization header
  auth_ref = try(each.value._tenant, null)
}

# ── Externals: billing account permission check ──────────────────────────────
# The Billing API returns HTTP 404 (not 403) when the caller lacks read access.
# Detect _warning on any azure_billing_accounts external and surface a clear hint.

locals {
  _billing_account_warnings = {
    for k, v in try(local._externals.azure_billing_accounts, {}) :
    k => try(v._warning, null) if try(v._warning, null) != null
  }
  _billing_scope_warnings = {
    for k, v in try(local._externals.azure_billing_scopes, {}) :
    k => try(v._warning, null) if try(v._warning, null) != null
  }
}

check "billing_account_external_access" {
  assert {
    condition     = length(local._billing_account_warnings) == 0
    error_message = <<-EOT
      One or more billing account externals returned a warning (likely HTTP 404).
      The Azure Billing API returns 404 when the caller does not have read access
      to the billing account — this is a permissions issue, not a missing resource.

      Affected accounts: ${join(", ", [for k, w in local._billing_account_warnings : "${k}: ${w}"])}

      To fix:
        1. Ensure you have 'Billing Account Reader' or 'Billing Account Owner' role.
        2. If you have a PIM eligible assignment, activate it first:
           Portal → Cost Management + Billing → Access control (IAM) → Eligible assignments
        3. Refresh your token:
           export TF_VAR_azure_access_token=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
    EOT
  }
}

check "billing_scope_external_access" {
  assert {
    condition     = length(local._billing_scope_warnings) == 0
    error_message = <<-EOT
      One or more billing scope externals returned a warning (likely HTTP 404).
      The Azure Billing API returns 404 when the caller lacks read access to the
      billing profile or invoice section — this is a permissions issue, not a missing resource.

      Affected scopes: ${join(", ", [for k, w in local._billing_scope_warnings : "${k}: ${w}"])}

      To fix:
        1. Ensure you have 'Billing Profile Reader' or 'Invoice Section Reader' role on the scope.
        2. If you have a PIM eligible assignment, activate it first:
           Portal → Cost Management + Billing → Access control (IAM) → Eligible assignments
        3. Refresh your token:
           export TF_VAR_azure_access_token=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
    EOT
  }
}
