# ── Scope ────────────────────────────────────────────────────────────────────

variable "owner" {
  type        = string
  description = "The account owner of the repository (user or organization)."
}

variable "repo" {
  type        = string
  description = "The repository name (without .git extension)."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  type        = string
  description = "The name of the deployment environment (e.g. staging, production)."
}

# ── Optional protection rules ────────────────────────────────────────────────

variable "wait_timer" {
  type        = number
  default     = null
  description = "Amount of time (in minutes) to delay a job after it is initially triggered. Must be between 0 and 43200 (30 days)."
}

variable "prevent_self_review" {
  type        = bool
  default     = null
  description = "If true, the user who created the deployment cannot approve it."
}

variable "reviewers" {
  type = list(object({
    type = string # "User" or "Team"
    id   = number
  }))
  default     = null
  description = "Up to six users or teams that may review jobs referencing this environment. Each entry: { type = \"User\"|\"Team\", id = <numeric id> }."
}

variable "deployment_branch_policy" {
  type = object({
    protected_branches     = bool
    custom_branch_policies = bool
  })
  default     = null
  description = <<-EOT
    Deployment branch policy for the environment. Set to null to allow all branches to deploy.
    Exactly one of protected_branches / custom_branch_policies must be true:
      - protected_branches = true: only branches with branch protection rules can deploy.
      - custom_branch_policies = true: only branches matching configured name patterns can deploy
        (the patterns themselves must be managed via /repos/{owner}/{repo}/environments/{env}/deployment-branch-policies — out of scope for this module).
  EOT
}
