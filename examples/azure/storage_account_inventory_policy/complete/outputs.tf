output "azure_storage_account_inventory_policies" {
  description = "Map of inventory policy outputs from the root module, keyed by instance name."
  value       = module.root.azure_values.azure_storage_account_inventory_policies
}
