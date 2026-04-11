output "azure_storage_account_blob_services" {
  description = "Map of blob service outputs from the root module, keyed by instance name."
  value       = module.root.azure_values.azure_storage_account_blob_services
}
