# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}

variable "header" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Optional HTTP headers to override for this resource (e.g. cross-tenant Authorization)."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The subscription ID, used to normalise provider-relative role definition IDs."
}

variable "scope" {
  type        = string
  description = "The ARM resource ID of the scope for the role assignment (e.g. subscription, resource group, or resource)."
}

# ── Required body properties ──────────────────────────────────────────────────

variable "role_definition_id" {
  type        = string
  description = "The full ARM role definition ID (e.g. /subscriptions/{sub}/providers/Microsoft.Authorization/roleDefinitions/{guid})."
}

variable "principal_id" {
  type        = string
  description = "The object ID of the principal (user, group, or service principal) to assign the role to."
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "principal_type" {
  type        = string
  default     = "ServicePrincipal"
  description = "The type of the principal. Options: User, Group, ServicePrincipal, ForeignGroup, Device."
}

variable "description" {
  type        = string
  default     = null
  description = "Description of the role assignment."
}

variable "condition" {
  type        = string
  default     = null
  description = "The conditions on the role assignment."
}

variable "condition_version" {
  type        = string
  default     = null
  description = "Version of the condition. Currently only '2.0' is accepted."
}
