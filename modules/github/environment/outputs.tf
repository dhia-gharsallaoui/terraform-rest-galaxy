# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "name" {
  description = "The name of the deployment environment."
  value       = var.name
}

output "owner" {
  description = "The repository owner."
  value       = var.owner
}

output "repo" {
  description = "The repository name."
  value       = var.repo
}

# ── Known after apply (server-assigned) ───────────────────────────────────────

output "id" {
  description = "The numeric ID of the environment, assigned by GitHub."
  value       = try(rest_resource.environment.output.id, null)
}

output "node_id" {
  description = "The GraphQL node ID of the environment."
  value       = try(rest_resource.environment.output.node_id, null)
}

output "url" {
  description = "The API URL of the environment."
  value       = try(rest_resource.environment.output.url, null)
}

output "html_url" {
  description = "The HTML URL of the environment on github.com."
  value       = try(rest_resource.environment.output.html_url, null)
}
