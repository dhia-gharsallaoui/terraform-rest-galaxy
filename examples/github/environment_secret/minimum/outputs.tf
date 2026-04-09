output "github_environment_secrets" {
  description = "Map of environment secret outputs from the root module."
  value       = module.root.github_values.github_environment_secrets
}
