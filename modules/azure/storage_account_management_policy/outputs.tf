# Plan-time known — constructed from input variables
output "id" {
  description = "The full ARM resource ID of the management policy."
  value       = local.policy_path
}

# API version is always known at plan time (hard-coded in locals)
output "api_version" {
  description = "The ARM API version used to manage this resource."
  value       = local.api_version
}

# API-sourced — known after apply
output "last_modified_time" {
  description = "The date and time the management policy was last modified."
  value       = try(rest_resource.management_policy.output.properties.lastModifiedTime, null)
}
