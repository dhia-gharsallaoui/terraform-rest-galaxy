# ── Provider behaviour ─────────────────────────────────────────────────────

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "provisioning_billing_request_id" {
  type        = string
  default     = null
  description = <<-EOT
    The full ARM path of the billing request, as returned by the associated-tenant
    resource (e.g. /providers/Microsoft.Billing/billingRequests/<GUID>).
    The module extracts the GUID and builds the permissionRequests path.
    Mutually exclusive with billing_request_id.
  EOT
}

variable "billing_request_id" {
  type        = string
  default     = null
  description = <<-EOT
    The billing request GUID for GA billingRequests API (2024-04-01) approval.
    Used for invoice-section-scoped role assignment requests that require
    approval by an invoice section owner.
    Mutually exclusive with provisioning_billing_request_id.
  EOT
}

variable "status" {
  type        = string
  description = "The desired status for the permission request."
  validation {
    condition     = contains(["Approved", "Rejected"], var.status)
    error_message = "status must be 'Approved' or 'Rejected'."
  }
}
