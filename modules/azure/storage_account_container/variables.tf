variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The storage account name."
}

variable "container_name" {
  type        = string
  description = "The name of the blob container. Must be 3–63 lowercase alphanumeric characters or hyphens; cannot start or end with a hyphen."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.container_name)) || can(regex("^[a-z0-9]{3}$", var.container_name))
    error_message = "container_name must be 3–63 lowercase alphanumeric characters or hyphens and cannot start/end with a hyphen."
  }
}

variable "public_access" {
  type        = string
  default     = "None"
  description = "The level of public access. None = no public read; Blob = blobs publicly readable; Container = blobs + container listing publicly readable."

  validation {
    condition     = contains(["None", "Blob", "Container"], var.public_access)
    error_message = "public_access must be 'None', 'Blob', or 'Container'."
  }
}

variable "metadata" {
  type        = map(string)
  default     = null
  description = "A map of custom metadata key-value pairs for the container. Keys and values must be ASCII strings."
}

variable "default_encryption_scope" {
  type        = string
  default     = null
  description = "The default encryption scope applied to all blobs in this container. Overrides the storage account's default scope."
}

variable "deny_encryption_scope_override" {
  type        = bool
  default     = null
  description = "When true, prevents individual blobs from overriding the container's default encryption scope."
}

variable "enable_nfs_v3_all_squash" {
  type        = bool
  default     = null
  description = "Map all NFS v3 client UIDs/GIDs to the anonymous user. Only valid when NFSv3 is enabled on the storage account."
}

variable "enable_nfs_v3_root_squash" {
  type        = bool
  default     = null
  description = "Map the NFS v3 root user (UID 0) to the anonymous user. Only valid when NFSv3 is enabled on the storage account."
}

variable "immutable_storage_with_versioning_enabled" {
  type        = bool
  default     = null
  description = "Enable container-level immutability (WORM) with versioning. Requires account-level immutable storage to be enabled."
}

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the container already exists before creating it. When true, the provider performs a GET before PUT. Set to true for brownfield import workflows."
}

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant authentication."
}
