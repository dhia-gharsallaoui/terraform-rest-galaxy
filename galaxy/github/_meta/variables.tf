# ── GitHub Variables ──────────────────────────────────────────────────────────

variable "github_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub personal access token or GitHub App token. Required when managing GitHub resources (repositories, teams, branch protection, etc.)."
}
