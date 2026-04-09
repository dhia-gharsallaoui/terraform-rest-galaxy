output "github_repositories" {
  description = "Map of repository outputs from the root module."
  value       = module.root.github_values.github_repositories
}
