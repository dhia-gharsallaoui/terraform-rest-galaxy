variable "access_token" {
  type        = string
  sensitive   = true
  default     = "placeholder"
  description = "Azure ARM access token. Not used by this github example but required by the root module."
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub personal access token with repo scope. Must be valid because the module fetches per-environment public keys at plan time."
}

variable "owner" {
  type        = string
  description = "The repository owner (user or organization)."
}

variable "repo" {
  type        = string
  description = "The repository name."
}

variable "staging_api_key" {
  type        = string
  sensitive   = true
  default     = "staging-placeholder"
  description = "Plain-text API key for the staging environment."
}

variable "production_api_key" {
  type        = string
  sensitive   = true
  default     = "production-placeholder"
  description = "Plain-text API key for the production environment."
}
