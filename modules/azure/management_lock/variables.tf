variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group to apply the lock to."
}

variable "lock_name" {
  type        = string
  description = "The name of the management lock."
}

variable "lock_level" {
  type        = string
  default     = "CanNotDelete"
  description = "The lock level. Possible values: CanNotDelete, ReadOnly."

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "lock_level must be 'CanNotDelete' or 'ReadOnly'."
  }
}

variable "notes" {
  type        = string
  default     = null
  description = "Notes about the lock (max 512 characters)."
}

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}
