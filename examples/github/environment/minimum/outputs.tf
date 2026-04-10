output "github_environments" {
  description = "Map of environment outputs from the root module."
  value       = module.root.github_values.github_environments
}
