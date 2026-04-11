# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID in which the resource group is created."
}

# ── Identity ──────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  default     = null
  description = "The name of the resource group to create or update."
}

# ── Required body properties ──────────────────────────────────────────────────

variable "location" {
  type        = string
  description = "The location of the resource group. It cannot be changed after the resource group has been created. It must be one of the supported Azure locations."
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "managed_by" {
  type        = string
  default     = null
  description = "The ID of the resource that manages this resource group."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "The tags attached to the resource group."
}

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}
