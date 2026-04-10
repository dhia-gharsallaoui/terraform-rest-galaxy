# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "When true, the provider GETs the repository before creating it and adopts it into state if it already exists. Use this to reconcile drift or when a previous apply left the resource orphaned."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "organization" {
  type        = string
  description = "The GitHub organization name that will own the repository."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  type        = string
  description = "The repository name (without .git extension). Must be unique inside the organization."
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "description" {
  type        = string
  default     = null
  description = "A short description of the repository."
}

variable "homepage" {
  type        = string
  default     = null
  description = "A URL with more information about the repository."
}

variable "visibility" {
  type        = string
  default     = "private"
  description = "The visibility of the repository. One of: public, private. (internal is GHEC/GHES only and not validated here.)"
}

variable "auto_init" {
  type        = bool
  default     = false
  description = "Pass true to create an initial commit with an empty README."
}

variable "gitignore_template" {
  type        = string
  default     = null
  description = "Desired language or platform .gitignore template (e.g. Terraform, Go, Node)."
}

variable "license_template" {
  type        = string
  default     = null
  description = "Open source license template keyword (e.g. mit, apache-2.0, mpl-2.0)."
}

variable "has_issues" {
  type        = bool
  default     = null
  description = "Enable or disable the issues feature for this repository."
}

variable "has_projects" {
  type        = bool
  default     = null
  description = "Enable or disable the projects feature for this repository."
}

variable "has_wiki" {
  type        = bool
  default     = null
  description = "Enable or disable the wiki feature for this repository."
}

variable "has_downloads" {
  type        = bool
  default     = null
  description = "Enable or disable the downloads feature for this repository."
}

variable "delete_branch_on_merge" {
  type        = bool
  default     = null
  description = "Automatically delete head branches when pull requests are merged."
}

variable "allow_squash_merge" {
  type        = bool
  default     = null
  description = "Allow squash-merging pull requests."
}

variable "allow_merge_commit" {
  type        = bool
  default     = null
  description = "Allow merging pull requests with a merge commit."
}

variable "allow_rebase_merge" {
  type        = bool
  default     = null
  description = "Allow rebase-merging pull requests."
}

variable "allow_auto_merge" {
  type        = bool
  default     = null
  description = "Allow auto-merge on pull requests."
}
