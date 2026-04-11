# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it."
}

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}

variable "precheck_access" {
  type        = bool
  default     = false
  description = "When true, calls the billing checkAccess API before creating the resource to verify the caller has write permission. Fails with a descriptive error if access is denied."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "billing_account_name" {
  type        = string
  description = "The ID that uniquely identifies the billing account (e.g. '12345678' or a GUID:GUID_YYYY-MM-DD format)."
}

variable "tenant_id" {
  type        = string
  description = "The tenant ID (GUID) of the tenant to associate with the billing account."
  validation {
    condition     = can(regex("^[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid GUID."
  }
}

# ── Required body properties ──────────────────────────────────────────────────

variable "display_name" {
  type        = string
  description = "A friendly name for the associated tenant (displayed in Cost Management + Billing)."
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "billing_management_state" {
  type        = string
  default     = "Active"
  description = "Whether users from the associated tenant can be assigned billing roles. One of: Active, NotAllowed, Revoked."
  validation {
    condition     = contains(["Active", "NotAllowed", "Revoked", "Other"], var.billing_management_state)
    error_message = "billing_management_state must be 'Active', 'NotAllowed', 'Revoked', or 'Other'."
  }
}

variable "provisioning_management_state" {
  type        = string
  default     = "NotRequested"
  description = "Whether subscriptions/licenses can be provisioned in the associated tenant. One of: Active, NotRequested, Pending, Revoked."
  validation {
    condition     = contains(["Active", "NotRequested", "Pending", "BillingRequestExpired", "BillingRequestDeclined", "Revoked", "Other"], var.provisioning_management_state)
    error_message = "provisioning_management_state must be one of: Active, NotRequested, Pending, BillingRequestExpired, BillingRequestDeclined, Revoked, Other."
  }
}
