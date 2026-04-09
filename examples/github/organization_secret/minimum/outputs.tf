output "github_organization_secrets" {
  description = "Map of organization secret outputs from the root module."
  value       = module.root.github_values.github_organization_secrets
}
