# ── Scope ─────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID in which the storage account resides."
}

# ── Parent scope ───────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The name of the storage account that hosts this local user."
}

# ── Identity ───────────────────────────────────────────────────────────────────

variable "username" {
  type        = string
  description = "The name of the local user. Must be 3–64 characters, lowercase alphanumeric and hyphens, cannot start or end with a hyphen."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$", var.username)) || can(regex("^[a-z0-9]{3}$", var.username))
    error_message = "username must be 3–64 characters, lowercase alphanumeric and hyphens, and cannot start or end with a hyphen."
  }
}

# ── Required body properties ───────────────────────────────────────────────────

variable "permission_scopes" {
  type = list(object({
    service       = string
    resource_name = string
    permissions   = string
  }))
  description = <<-EOT
    The permission scopes granted to the local user. Each scope specifies a service
    (blob or file), a resource name (container or share name), and a permissions
    string composed of characters: r (read), w (write), d (delete), l (list),
    c (create), m (move), x (execute), o (ownership), p (permissions).
  EOT

  validation {
    condition = alltrue([
      for s in var.permission_scopes : contains(["blob", "file"], s.service)
    ])
    error_message = "Each permission_scope.service must be 'blob' or 'file'."
  }

  validation {
    condition = alltrue([
      for s in var.permission_scopes : can(regex("^[rwdlcmxop]+$", s.permissions))
    ])
    error_message = "Each permission_scope.permissions must contain only the characters: r, w, d, l, c, m, x, o, p."
  }
}

# ── Optional body properties ───────────────────────────────────────────────────

variable "home_directory" {
  type        = string
  default     = null
  description = "Optional. The home directory path for the local user within the storage account (e.g. 'mycontainer/subdir')."
}

variable "ssh_authorized_keys" {
  type = list(object({
    description = string
    key         = string
  }))
  default     = null
  description = "Optional. A list of SSH public keys authorized for SFTP authentication. Each entry has a description and the SSH public key string."
}

variable "has_ssh_password" {
  type        = bool
  default     = null
  description = "Indicates whether an SSH password exists. Set to false to remove an existing SSH password. Read-only — informational only."
}

variable "allow_acl_authorization" {
  type        = bool
  default     = null
  description = "Indicates whether ACL authorization is allowed for this user. Set to false to disallow ACL authorization (POSIX ACLs). Defaults to true when not set."
}

variable "group_id" {
  type        = number
  default     = null
  description = "An identifier for associating a group of users. Used for NFSv3 local users."
}

variable "extended_groups" {
  type        = list(number)
  default     = null
  description = "Supplementary group membership. Only applicable for local users enabled for NFSv3 access."
}

# ── Provider behaviour ─────────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}
