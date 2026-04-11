# Plan-time known — constructed from input variables
output "id" {
  description = "The full ARM resource ID of the encryption scope."
  value       = local.scope_path
}

output "name" {
  description = "The encryption scope name (plan-time, echoes input)."
  value       = var.encryption_scope_name
}

# API version is always known at plan time (hard-coded in locals)
output "api_version" {
  description = "The ARM API version used to manage this resource."
  value       = local.api_version
}

# API-sourced — known after apply
output "state" {
  description = "The current state of the encryption scope: Enabled or Disabled."
  value       = try(rest_resource.encryption_scope.output.properties.state, null)
}

output "created_on" {
  description = "The date and time the encryption scope was created."
  value       = try(rest_resource.encryption_scope.output.properties.creationTime, null)
}

output "last_modified_time" {
  description = "The date and time the encryption scope was last modified."
  value       = try(rest_resource.encryption_scope.output.properties.lastModifiedTime, null)
}

output "provisioning_state" {
  description = "The provisioning state of the encryption scope."
  value       = try(rest_resource.encryption_scope.output.properties.provisioningState, null)
}
