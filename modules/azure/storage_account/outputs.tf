output "id" {
  description = "The full ARM resource ID of the storage account."
  value       = local.sa_path
}

output "api_version" {
  description = "The ARM API version used to manage this storage account."
  value       = "2025-08-01"
}

# Read-only properties surfaced from the ARM GET response.

output "name" {
  description = "The name of the storage account (plan-time, echoes input)."
  value       = var.account_name
}

output "type" {
  description = "The resource type string returned by ARM (Microsoft.Storage/storageAccounts)."
  value       = try(rest_resource.storage_account.output.type, null)
}

output "location" {
  description = "The Azure region where the storage account is deployed (plan-time, echoes input)."
  value       = var.location
}

output "kind" {
  description = "The kind of the storage account (plan-time, echoes input)."
  value       = var.kind
}

output "sku_name" {
  description = "The SKU name of the storage account (plan-time, echoes input)."
  value       = var.sku_name
}

output "provisioning_state" {
  description = "The provisioning state of the storage account (e.g. Succeeded)."
  value       = try(rest_resource.storage_account.output.properties.provisioningState, null)
}

output "primary_blob_endpoint" {
  description = "The primary Blob service endpoint URL."
  value       = try(rest_resource.storage_account.output.properties.primaryEndpoints.blob, null)
}

output "primary_file_endpoint" {
  description = "The primary File service endpoint URL."
  value       = try(rest_resource.storage_account.output.properties.primaryEndpoints.file, null)
}

output "primary_queue_endpoint" {
  description = "The primary Queue service endpoint URL."
  value       = try(rest_resource.storage_account.output.properties.primaryEndpoints.queue, null)
}

output "primary_table_endpoint" {
  description = "The primary Table service endpoint URL."
  value       = try(rest_resource.storage_account.output.properties.primaryEndpoints.table, null)
}

output "primary_dfs_endpoint" {
  description = "The primary Data Lake Storage Gen2 (DFS) endpoint URL."
  value       = try(rest_resource.storage_account.output.properties.primaryEndpoints.dfs, null)
}

output "primary_web_endpoint" {
  description = "The primary static website endpoint URL (requires static website feature enabled)."
  value       = try(rest_resource.storage_account.output.properties.primaryEndpoints.web, null)
}

output "primary_microsoft_blob_endpoint" {
  description = "The primary Blob endpoint routed through the Microsoft network (when publish_microsoft_endpoints = true)."
  value       = try(rest_resource.storage_account.output.properties.primaryEndpoints.microsoftEndpoints.blob, null)
}

output "primary_internet_blob_endpoint" {
  description = "The primary Blob endpoint routed through the internet (when publish_internet_endpoints = true)."
  value       = try(rest_resource.storage_account.output.properties.primaryEndpoints.internetEndpoints.blob, null)
}

output "secondary_blob_endpoint" {
  description = "The secondary Blob service endpoint URL (available for GRS and RAGRS accounts)."
  value       = try(rest_resource.storage_account.output.properties.secondaryEndpoints.blob, null)
}

output "secondary_dfs_endpoint" {
  description = "The secondary DFS endpoint URL (available for ADLS Gen2 GRS/RAGRS accounts)."
  value       = try(rest_resource.storage_account.output.properties.secondaryEndpoints.dfs, null)
}

output "identity_principal_id" {
  description = "The Principal ID of the system-assigned managed identity (null when identity_type = None or no identity)."
  value       = try(rest_resource.storage_account.output.identity.principalId, null)
}

output "identity_tenant_id" {
  description = "The Tenant ID of the system-assigned managed identity."
  value       = try(rest_resource.storage_account.output.identity.tenantId, null)
}
