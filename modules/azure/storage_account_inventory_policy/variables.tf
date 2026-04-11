# ── Scope ─────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID containing the storage account."
}

# ── Parent scope ───────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The name of the storage account for which to configure the inventory policy."
}

# ── Required body properties ───────────────────────────────────────────────────

variable "rules" {
  type = list(object({
    name                  = string
    enabled               = optional(bool, true)
    destination           = string
    schedule              = string
    object_type           = string
    format                = string
    schema_fields         = list(string)
    include_snapshots     = optional(bool, false)
    include_blob_versions = optional(bool, false)
    include_deleted       = optional(bool, false)
    prefix_match          = optional(list(string), [])
    blob_types            = optional(list(string), ["blockBlob"])
    exclude_prefix        = optional(list(string), [])
  }))
  description = <<-EOT
    The blob inventory policy rules. Each rule defines a periodic inventory report
    written to the specified destination container.

    name:                 Unique rule name within the policy (case-sensitive).
    enabled:              Whether the rule is active (default true).
    destination:          Container name where inventory files are stored.
    schedule:             'Daily' or 'Weekly'.
    object_type:          'Blob' or 'Container'.
    format:               'Csv' or 'Parquet'.
    schema_fields:        List of fields to include in the inventory report.
                          'Name' is always required. Valid Blob fields include:
                          Creation-Time, Last-Modified, Content-Length, BlobType,
                          AccessTier, Snapshot, VersionId, IsCurrentVersion,
                          Metadata, LastAccessTime, Tags, Etag, etc.
                          Valid Container fields include: Last-Modified, Metadata,
                          LeaseStatus, PublicAccess, HasImmutabilityPolicy, etc.
    include_snapshots:    Include blob snapshots (Blob object_type only).
    include_blob_versions: Include blob versions (Blob object_type only).
    include_deleted:      Include soft-deleted blobs or containers.
    prefix_match:         Up to 10 blob name prefixes to include.
    blob_types:           Blob types to include: blockBlob, appendBlob, pageBlob.
                          Required when object_type = Blob.
    exclude_prefix:       Up to 10 blob name prefixes to exclude.
  EOT

  validation {
    condition = alltrue([
      for r in var.rules : contains(["Daily", "Weekly"], r.schedule)
    ])
    error_message = "Each rule.schedule must be 'Daily' or 'Weekly'."
  }

  validation {
    condition = alltrue([
      for r in var.rules : contains(["Blob", "Container"], r.object_type)
    ])
    error_message = "Each rule.object_type must be 'Blob' or 'Container'."
  }

  validation {
    condition = alltrue([
      for r in var.rules : contains(["Csv", "Parquet"], r.format)
    ])
    error_message = "Each rule.format must be 'Csv' or 'Parquet'."
  }
}

# ── Provider behaviour ─────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
