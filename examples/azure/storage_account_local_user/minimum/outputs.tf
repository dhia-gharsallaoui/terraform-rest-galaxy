output "azure_storage_account_local_users" {
  description = "Map of storage account local user outputs from the root module, keyed by instance name."
  value       = module.root.azure_values.azure_storage_account_local_users
}
