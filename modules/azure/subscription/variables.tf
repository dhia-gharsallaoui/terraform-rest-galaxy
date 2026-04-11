# ── Identity ──────────────────────────────────────────────────────────────────

variable "alias_name" {
  type        = string
  description = "The alias name for the subscription. Used as the resource path identifier."
}

# ── Required body properties ──────────────────────────────────────────────────

variable "display_name" {
  type        = string
  description = "The friendly display name of the subscription."
}

variable "billing_scope" {
  type        = string
  description = <<-EOT
    Billing scope of the subscription.
    For CustomerLed and FieldLed: /billingAccounts/{billingAccountName}/billingProfiles/{billingProfileName}/invoiceSections/{invoiceSectionName}
    For PartnerLed: /billingAccounts/{billingAccountName}/customers/{customerName}
    For Legacy EA: /billingAccounts/{billingAccountName}/enrollmentAccounts/{enrollmentAccountName}
  EOT
}

variable "workload" {
  type        = string
  description = "The workload type of the subscription: Production or DevTest."
  validation {
    condition     = contains(["Production", "DevTest"], var.workload)
    error_message = "workload must be 'Production' or 'DevTest'."
  }
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  default     = null
  description = "Existing subscription ID to create an alias for. When null, a new subscription is created."
}

variable "reseller_id" {
  type        = string
  default     = null
  description = "Reseller ID for the subscription."
}

variable "management_group_id" {
  type        = string
  default     = null
  description = "Management group ID for the subscription."
}

variable "subscription_tenant_id" {
  type        = string
  default     = null
  description = "Tenant ID of the subscription."
}

variable "subscription_owner_id" {
  type        = string
  default     = null
  description = "Owner ID of the subscription."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags for the subscription."
}

# ── Provider behaviour ─────────────────────────────────────────────────────

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
