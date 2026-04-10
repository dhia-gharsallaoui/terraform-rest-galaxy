variable "access_token" {
  type        = string
  sensitive   = true
  default     = "placeholder"
  description = "Azure ARM access token. Not used by this github example but required by the root module."
}

variable "github_token" {
  type        = string
  sensitive   = true
  default     = "placeholder"
  description = "GitHub personal access token with repo scope."
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

variable "variable_name" {
  type        = string
  description = "The environment-scoped variable name (e.g. API_URL)."
}

variable "variable_value" {
  type        = string
  description = "The environment-scoped variable value."
}
