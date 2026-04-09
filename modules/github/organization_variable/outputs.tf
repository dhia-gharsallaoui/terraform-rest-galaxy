# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "name" {
  description = "The name of the organization-scoped Actions variable."
  value       = var.name
}

output "organization" {
  description = "The GitHub organization."
  value       = var.organization
}

output "value" {
  description = "The current value of the variable (plan-time, echoes input)."
  value       = var.value
}

output "visibility" {
  description = "Which type of organization repositories can access the variable (all, private, selected)."
  value       = var.visibility
}
