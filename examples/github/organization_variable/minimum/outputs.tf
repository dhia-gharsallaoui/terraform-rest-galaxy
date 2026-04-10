output "github_organization_variables" {
  description = "Map of organization variable outputs from the root module."
  value       = module.root.github_values.github_organization_variables
}
