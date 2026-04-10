# ── Scope ────────────────────────────────────────────────────────────────────

variable "owner" {
  type        = string
  description = "The account owner of the repository (user or organization)."
}

variable "repo" {
  type        = string
  description = "The repository name (without .git extension)."
}

variable "environment_name" {
  type        = string
  description = "The name of the deployment environment (e.g. staging, production)."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "secret_name" {
  type        = string
  description = "The name of the environment-scoped Actions secret (e.g. API_KEY)."
}

variable "plaintext_value" {
  type        = string
  sensitive   = true
  description = "The secret value in plain text. It will be encrypted with the environment's public key before upload."
}
