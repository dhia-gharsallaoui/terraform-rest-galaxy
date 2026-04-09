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
  description = "GitHub personal access token with admin:org scope."
}

variable "organization" {
  type        = string
  description = "The GitHub organization name."
}

variable "variable_name" {
  type        = string
  description = "The organization-scoped variable name."
}

variable "variable_value" {
  type        = string
  description = "The organization-scoped variable value."
}

variable "selected_repository_ids" {
  type        = list(number)
  description = "Numeric repository IDs that can access the variable (required when visibility = \"selected\")."
}
