output "azure_storage_account_file_services" {
  description = "Map of file service outputs from the root module, keyed by instance name."
  value       = module.root.azure_values.azure_storage_account_file_services
}
