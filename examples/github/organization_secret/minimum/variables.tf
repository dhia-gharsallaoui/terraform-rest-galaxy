variable "access_token" {
  type        = string
  sensitive   = true
  default     = "placeholder"
  description = "Azure ARM access token. Not used by this github example but required by the root module."
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub personal access token with admin:org scope. Must be valid because the module fetches the org public key at plan time."
}

variable "organization" {
  type        = string
  description = "The GitHub organization name."
}

variable "secret_name" {
  type        = string
  description = "The organization-scoped secret name (e.g. NPM_TOKEN)."
}

variable "plaintext_value" {
  type        = string
  sensitive   = true
  description = "The secret value in plain text."
}
