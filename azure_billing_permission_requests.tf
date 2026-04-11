# ── Billing Permission Requests (approval automation) ────────────────────────
#
# Automates the Global Admin approval of billing provisioning requests.
# The permissionRequests endpoint (2020-11-01-privatepreview) is the target-tenant
# side of the billingRequests created when an associated tenant sets
# provisioning_management_state = "Pending".
#
# The _tenant must point to the TARGET tenant (the one being associated),
# because the approval must be performed by a Global Admin of that tenant.

variable "azure_billing_permission_requests" {
  type = map(object({
    associated_tenant  = optional(string, null)
    billing_request_id = optional(string, null)
    status             = optional(string, "Approved")
    _tenant            = optional(string, null)
  }))
  description = <<-EOT
    Map of billing permission/request approvals. Each map key acts as the
    for_each identifier.

    Exactly one of associated_tenant or billing_request_id must be set:

    associated_tenant — key into azure_billing_associated_tenants whose
    provisioningBillingRequestId will be approved via the permissionRequests
    private-preview API. _tenant should be the TARGET tenant.

    billing_request_id — the GUID of a billingRequest to approve via the
    GA billingRequests API (2024-04-01). Used for invoice-section-scoped
    role assignment requests. _tenant should be the BILLING tenant
    (approval requires invoice section owner permissions).
    Get the GUID from the first apply output or the Azure portal.

    Example:
      azure_billing_permission_requests = {
        approve_partner = {
          associated_tenant = "partner"
          status  = "Approved"
          _tenant = "target-tenant-id"
        }
        approve_role = {
          billing_request_id = "895fb3ca-5ba7-40d0-a6a1-b4601518d564"
          status  = "Approved"
          _tenant = "billing-tenant-id"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_billing_permission_requests = provider::rest::resolve_map(
    { externals = local._externals, remote_states = var.remote_states },
    merge(try(local._yaml_raw.azure_billing_permission_requests, {}), var.azure_billing_permission_requests)
  )
  _bpr_ctx = provider::rest::merge_with_outputs(local.azure_billing_permission_requests, module.azure_billing_permission_requests)
}

module "azure_billing_permission_requests" {
  source = "./modules/azure/billing_permission_request"
  # Provisioning requests: only when associated tenant has a pending request.
  # Billing requests: always included when billing_request_id is set.
  for_each = merge(
    {
      for k, v in local.azure_billing_permission_requests : k => v
      if try(v.associated_tenant, null) != null && try(local.azure_billing_associated_tenants[v.associated_tenant].provisioning_management_state, "Active") == "Pending"
    },
    {
      for k, v in local.azure_billing_permission_requests : k => v
      if try(v.billing_request_id, null) != null
    },
  )

  provisioning_billing_request_id = try(each.value.associated_tenant, null) != null ? module.azure_billing_associated_tenants[each.value.associated_tenant].provisioning_billing_request_id : null
  billing_request_id              = try(each.value.billing_request_id, null)
  status                          = try(each.value.status, "Approved")

  # Cross-tenant: approval runs in the appropriate tenant
  auth_ref = try(each.value._tenant, null)
}
