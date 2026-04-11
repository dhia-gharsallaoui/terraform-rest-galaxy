# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the role assignment already exists before creating it."
}

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "billing_account_name" {
  type        = string
  description = "The billing account ID (e.g. '12345678-...:12345678-..._2019-05-31')."
}

variable "billing_scope" {
  type        = string
  default     = null
  description = <<-EOT
    Optional billing scope path to assign the role at a sub-account level
    (billing profile or invoice section). When null, the role is assigned at
    the billing account level.

    Example (invoice section):
      /providers/Microsoft.Billing/billingAccounts/{name}/billingProfiles/{profile}/invoiceSections/{section}
  EOT
}

variable "principal_id" {
  type        = string
  description = "The object ID of the principal (user, group, or service principal) to assign the role to."
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.principal_id))
    error_message = "principal_id must be a valid GUID."
  }
}

variable "principal_tenant_id" {
  type        = string
  description = "The tenant ID of the principal."
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.principal_tenant_id))
    error_message = "principal_tenant_id must be a valid GUID."
  }
}

variable "role_definition_id" {
  type        = string
  description = <<-EOT
    The billing role definition ID. Can be a full path or just the GUID name.
    Full path example: /providers/Microsoft.Billing/billingAccounts/{name}/billingRoleDefinitions/{guid}
    GUID-only example: 10000000-aaaa-bbbb-cccc-100000000002
  EOT
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "principal_type" {
  type        = string
  default     = "ServicePrincipal"
  description = "The type of the principal. Options: User, Group, ServicePrincipal, DirectoryRole, Everyone."
  validation {
    condition     = contains(["Unknown", "None", "User", "Group", "DirectoryRole", "ServicePrincipal", "Everyone"], var.principal_type)
    error_message = "principal_type must be one of: Unknown, None, User, Group, DirectoryRole, ServicePrincipal, Everyone."
  }
}

variable "user_email_address" {
  type        = string
  default     = null
  description = "The email address of the user. Supported only for Enterprise Agreement billing accounts."
}

variable "billing_request_id" {
  type        = string
  default     = null
  description = <<-EOT
    The billing request GUID from a previous POST at a scope that requires
    approval (e.g. invoice section). When set, the module skips the POST
    (request already exists) and outputs this ID directly.
  EOT
}
