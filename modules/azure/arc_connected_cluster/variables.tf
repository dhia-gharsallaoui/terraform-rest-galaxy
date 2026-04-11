# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group name."
}

variable "cluster_name" {
  type        = string
  description = "The name of the connected cluster resource."
}

# ── Required body properties ──────────────────────────────────────────────────

variable "location" {
  type        = string
  description = "The Azure region for the connected cluster."
}

variable "agent_public_key_certificate" {
  type        = string
  description = "Base64 encoded public certificate used by the agent to do the initial handshake to the backend services in Azure."
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "identity_type" {
  type        = string
  default     = "SystemAssigned"
  description = "The type of identity used for the connected cluster (SystemAssigned or None)."
}

variable "kind" {
  type        = string
  default     = null
  description = "Indicates the kind of Arc connected cluster based on host infrastructure (e.g. ProvisionedCluster)."
}

variable "distribution" {
  type        = string
  default     = null
  description = "The Kubernetes distribution running on this connected cluster."
}

variable "distribution_version" {
  type        = string
  default     = null
  description = "The Kubernetes distribution version on this connected cluster."
}

variable "infrastructure" {
  type        = string
  default     = null
  description = "The infrastructure on which the Kubernetes cluster is running."
}

variable "private_link_state" {
  type        = string
  default     = null
  description = "Property which describes the state of private link on a connected cluster resource (Enabled or Disabled)."
}

variable "private_link_scope_resource_id" {
  type        = string
  default     = null
  description = "The resource id of the private link scope this connected cluster is assigned to."
}

variable "azure_hybrid_benefit" {
  type        = string
  default     = null
  description = "Indicates whether Azure Hybrid Benefit is opted in (True, False, or NotApplicable)."
}

variable "aad_profile" {
  type = object({
    enable_azure_rbac      = optional(bool, null)
    admin_group_object_ids = optional(list(string), [])
    tenant_id              = optional(string, null)
  })
  default     = null
  description = "AAD Profile for Azure Active Directory integration."
}

variable "arc_agent_profile" {
  type = object({
    desired_agent_version = optional(string, null)
    agent_auto_upgrade    = optional(string, "Enabled")
  })
  default     = null
  description = "Arc Agent profile configuration."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Resource tags."
}

# ── Post-create behaviour ────────────────────────────────────────────────────

variable "wait_for_connection" {
  type        = bool
  default     = true
  description = "Wait for the Arc agent to reach 'Connected' status after resource creation. When true, Terraform polls the cluster until connectivityStatus is Connected (up to ~10 minutes)."
}

# ── Auth ─────────────────────────────────────────────────────────────────────

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}
