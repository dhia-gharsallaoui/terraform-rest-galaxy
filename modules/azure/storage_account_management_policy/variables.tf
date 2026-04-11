# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID in which the storage account resides."
}

# ── Parent scope ──────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The name of the storage account for which the management policy is created."
}

# ── Policy rules ──────────────────────────────────────────────────────────────

variable "rules" {
  type = list(object({
    name    = string
    enabled = optional(bool, true)
    filters = optional(object({
      blob_types   = list(string)
      prefix_match = optional(list(string), [])
      blob_index_match = optional(list(object({
        name      = string
        operation = optional(string, "==")
        value     = string
      })), [])
    }))
    actions = object({
      base_blob = optional(object({
        tier_to_cool_after_days_since_modification_greater_than        = optional(number, null)
        tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number, null)
        tier_to_cold_after_days_since_modification_greater_than        = optional(number, null)
        tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number, null)
        tier_to_archive_after_days_since_modification_greater_than     = optional(number, null)
        tier_to_archive_after_days_since_last_access_time_greater_than = optional(number, null)
        delete_after_days_since_modification_greater_than              = optional(number, null)
        delete_after_days_since_last_access_time_greater_than          = optional(number, null)
        enable_auto_tier_to_hot_from_cool                              = optional(bool, null)
      }), null)
      snapshot = optional(object({
        change_tier_to_cool_after_days_since_creation    = optional(number, null)
        change_tier_to_cold_after_days_since_creation    = optional(number, null)
        change_tier_to_archive_after_days_since_creation = optional(number, null)
        delete_after_days_since_creation_greater_than    = optional(number, null)
      }), null)
      version = optional(object({
        change_tier_to_cool_after_days_since_creation    = optional(number, null)
        change_tier_to_cold_after_days_since_creation    = optional(number, null)
        change_tier_to_archive_after_days_since_creation = optional(number, null)
        delete_after_days_since_creation                 = optional(number, null)
      }), null)
    })
  }))
  description = <<-EOT
    List of lifecycle management rules. Each rule defines filters (blob types,
    prefix matches, tag matches) and actions (tiering and deletion) applied to
    matching blobs. Only one management policy named "default" is allowed per
    storage account.

    Example:
      rules = [
        {
          name    = "delete-old-blobs"
          enabled = true
          filters = {
            blob_types   = ["blockBlob"]
            prefix_match = ["data/cold/"]
          }
          actions = {
            base_blob = {
              tier_to_cool_after_days_since_modification_greater_than    = 30
              tier_to_archive_after_days_since_modification_greater_than = 180
              delete_after_days_since_modification_greater_than          = 365
            }
          }
        }
      ]
  EOT
}

# ── Import / brownfield ───────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "When true the provider performs a GET before PUT and imports the resource into state if it already exists. Use for brownfield import workflows."
}
