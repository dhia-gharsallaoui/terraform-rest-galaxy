# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "name" {
  description = "The name of the organization-scoped Actions secret."
  value       = var.secret_name
}

output "organization" {
  description = "The GitHub organization."
  value       = var.organization
}

output "visibility" {
  description = "Which type of organization repositories have access to the secret (all, private, selected)."
  value       = var.visibility
}
