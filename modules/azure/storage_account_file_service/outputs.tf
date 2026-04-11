# Plan-time outputs — derived from input variables, known before apply.

output "id" {
  description = "The full ARM resource ID of the file service (always 'default' singleton path)."
  value       = local.file_svc_path
}

output "api_version" {
  description = "The ARM API version used to manage this resource."
  value       = local.api_version
}

# API-sourced outputs — known after apply.

output "provisioning_state" {
  description = "The provisioning state of the file service (e.g. Succeeded)."
  value       = try(rest_resource.file_service.output.properties.provisioningState, null)
}
