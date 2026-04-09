# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "name" {
  description = "The name of the environment-scoped Actions variable."
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

output "environment_name" {
  description = "The deployment environment name."
  value       = var.environment_name
}

output "value" {
  description = "The current value of the variable (plan-time, echoes input)."
  value       = var.value
}
