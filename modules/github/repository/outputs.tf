# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "name" {
  description = "The name of the repository."
  value       = var.name
}

output "organization" {
  description = "The GitHub organization that owns the repository."
  value       = var.organization
}

output "visibility" {
  description = "The visibility of the repository (public, private)."
  value       = var.visibility
}

# ── Known after apply (server-assigned) ───────────────────────────────────────

output "id" {
  description = "The numeric database ID of the repository, assigned by GitHub. Stable across renames."
  value       = try(rest_resource.repository.output.id, null)
}

output "node_id" {
  description = "The GraphQL node ID of the repository."
  value       = try(rest_resource.repository.output.node_id, null)
}

output "full_name" {
  description = "The full name of the repository in owner/name form."
  value       = try(rest_resource.repository.output.full_name, "${var.organization}/${var.name}")
}

output "html_url" {
  description = "The HTTPS URL of the repository on github.com."
  value       = try(rest_resource.repository.output.html_url, null)
}

output "ssh_url" {
  description = "The SSH clone URL of the repository."
  value       = try(rest_resource.repository.output.ssh_url, null)
}

output "clone_url" {
  description = "The HTTPS clone URL of the repository."
  value       = try(rest_resource.repository.output.clone_url, null)
}

output "default_branch" {
  description = "The default branch of the repository (set by GitHub after creation)."
  value       = try(rest_resource.repository.output.default_branch, null)
}
