output "azure_foundry_managed_networks" {
  description = "Map of Foundry managed network outputs from the root module, keyed by instance name."
  value       = module.root.azure_values.azure_foundry_managed_networks
}
