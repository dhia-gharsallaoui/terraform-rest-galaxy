output "azure_storage_account_containers" {
  description = "Map of blob container outputs from the root module, keyed by instance name."
  value       = module.root.azure_values.azure_storage_account_containers
}
