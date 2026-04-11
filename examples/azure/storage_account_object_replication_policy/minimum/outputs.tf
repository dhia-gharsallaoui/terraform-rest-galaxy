output "azure_storage_account_object_replication_policies" {
  description = "Map of object replication policy outputs from the root module, keyed by instance name."
  value       = module.root.azure_values.azure_storage_account_object_replication_policies
}
