# Plan-time outputs — derived from input variables.

output "id" {
  description = "The full ARM resource ID of the local user."
  value       = local.local_user_path
}

output "name" {
  description = "The username of the local user (plan-time, echoes input)."
  value       = var.username
}

output "api_version" {
  description = "The ARM API version used to manage this local user."
  value       = "2025-08-01"
}

# API-sourced outputs — assigned by Azure at creation time.

output "has_ssh_key" {
  description = "Indicates whether an SSH key exists for this local user."
  value       = try(rest_resource.local_user.output.properties.hasSshKey, null)
}

output "has_ssh_password" {
  description = "Indicates whether an SSH password exists for this local user."
  value       = try(rest_resource.local_user.output.properties.hasSshPassword, null)
}

output "sid" {
  description = "The Security Identifier (SID) assigned by Azure for this local user."
  value       = try(rest_resource.local_user.output.properties.sid, null)
}

output "user_id" {
  description = "The unique numeric identifier assigned by Azure for this local user."
  value       = try(rest_resource.local_user.output.properties.userId, null)
}
