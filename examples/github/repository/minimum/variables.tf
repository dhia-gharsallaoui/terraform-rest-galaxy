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
  description = "GitHub personal access token with repo + admin:org scope."
}

variable "organization" {
  type        = string
  description = "The GitHub organization that will own the repository."
}

variable "repository_name" {
  type        = string
  description = "The repository name to create."
}
