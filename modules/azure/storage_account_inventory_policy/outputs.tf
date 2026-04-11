# Plan-time outputs — derived from input variables.

output "id" {
  description = "The full ARM resource ID of the blob inventory policy."
  value       = local.policy_path
}

output "api_version" {
  description = "The ARM API version used to manage this blob inventory policy."
  value       = "2025-08-01"
}

# API-sourced outputs — assigned by Azure at creation time.

output "last_modified_time" {
  description = "The datetime when the inventory policy was last modified."
  value       = try(rest_resource.inventory_policy.output.properties.lastModifiedTime, null)
}
