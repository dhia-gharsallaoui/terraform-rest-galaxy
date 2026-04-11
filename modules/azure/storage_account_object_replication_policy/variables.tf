# ── Scope ─────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID containing the destination storage account."
}

# ── Parent scope ───────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the destination storage account."
}

variable "account_name" {
  type        = string
  description = "The name of the destination storage account for object replication."
}

# ── Policy identity ────────────────────────────────────────────────────────────

variable "policy_id" {
  type        = string
  default     = "default"
  description = "The object replication policy ID. Use 'default' when creating a new policy — Azure assigns a unique ID and returns it. Use the assigned ID on subsequent updates."
}

# ── Required body properties ───────────────────────────────────────────────────

variable "source_account" {
  type        = string
  description = "The full ARM resource ID of the source storage account. Required when allowCrossTenantReplication is false on either account."
}

variable "rules" {
  type = list(object({
    rule_id               = optional(string, null)
    source_container      = string
    destination_container = string
    min_creation_time     = optional(string, null)
    prefix_match          = optional(list(string), [])
  }))
  description = <<-EOT
    The replication rules defining which containers are replicated and optional filters.
    Each rule maps a source container to a destination container.
    rule_id is auto-assigned for new rules on the destination account; supply it when
    creating the corresponding policy on the source account.
    min_creation_time: ISO 8601 datetime — only blobs created after this time are replicated.
    prefix_match: list of blob name prefixes to replicate (up to 10).
  EOT
}

# ── Optional body properties ───────────────────────────────────────────────────

variable "metrics_enabled" {
  type        = bool
  default     = null
  description = "Optional. Enable object replication metrics for this policy."
}

variable "priority_replication_enabled" {
  type        = bool
  default     = null
  description = "Optional. Enable priority replication for this policy."
}

variable "tags_replication_enabled" {
  type        = bool
  default     = null
  description = "Optional. Enable blob tag replication as part of object replication."
}

# ── Provider behaviour ─────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
