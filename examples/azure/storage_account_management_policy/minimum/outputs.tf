output "azure_storage_account_management_policies" {
  description = "All management policy module outputs keyed by the instance name."
  value       = module.root.azure_values.azure_storage_account_management_policies
}
