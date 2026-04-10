variable "access_token" {
  type        = string
  sensitive   = true
  default     = "placeholder"
  description = "Azure ARM access token. Not used by this github example but required by the root module."
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub personal access token with repo scope. Must be valid because the module fetches the environment's public key at plan time."
}

variable "owner" {
  type        = string
  description = "The repository owner (user or organization)."
}

variable "repo" {
  type        = string
  description = "The repository name."
}

variable "environment_name" {
  type        = string
  description = "The deployment environment name."
}

variable "secret_name" {
  type        = string
  description = "The environment-scoped secret name."
}

variable "plaintext_value" {
  type        = string
  sensitive   = true
  description = "The secret value in plain text."
}
