# Plan-time outputs — derived from input variables, known before apply.

output "id" {
  description = "The full ARM resource ID of the blob service (always 'default' singleton path)."
  value       = local.blob_svc_path
}

output "api_version" {
  description = "The ARM API version used to manage this resource."
  value       = local.api_version
}

# API-sourced outputs — known after apply.

output "sku_name" {
  description = "The SKU name of the blob service as returned by Azure (e.g. Standard_LRS)."
  value       = try(rest_resource.blob_service.output.sku.name, null)
}

output "provisioning_state" {
  description = "The provisioning state of the blob service (e.g. Succeeded)."
  value       = try(rest_resource.blob_service.output.properties.provisioningState, null)
}
