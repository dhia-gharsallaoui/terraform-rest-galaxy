output "azure_foundry_accounts" {
  description = "Map of Foundry account outputs from the root module, keyed by instance name."
  value       = module.root.azure_values.azure_foundry_accounts
}
