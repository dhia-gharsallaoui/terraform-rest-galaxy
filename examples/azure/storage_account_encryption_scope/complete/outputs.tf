output "azure_storage_account_encryption_scopes" {
  description = "All encryption scope module outputs keyed by the instance name."
  value       = module.root.azure_values.azure_storage_account_encryption_scopes
}
