output "github_environment_variables" {
  description = "Map of environment variable outputs from the root module."
  value       = module.root.github_values.github_environment_variables
}
