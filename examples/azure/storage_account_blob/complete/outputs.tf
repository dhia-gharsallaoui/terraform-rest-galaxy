output "azure_storage_account_blobs" {
  description = "Map of all blob outputs, keyed by the same keys as the input map."
  value       = module.root.azure_values["azure_storage_account_blobs"]
}
