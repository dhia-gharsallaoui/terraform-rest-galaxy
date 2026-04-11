output "id" {
  description = "The full ARM resource ID of the blob container."
  value       = local.container_path
}

output "name" {
  description = "The container name (plan-time, echoes input)."
  value       = var.container_name
}

output "api_version" {
  description = "The ARM API version used to manage this container."
  value       = local.api_version
}

output "public_access" {
  description = "The public access level set on the container."
  value       = try(rest_resource.container.output.properties.publicAccess, null)
}

output "etag" {
  description = "The ETag value of the container (changes on every metadata update)."
  value       = try(rest_resource.container.output.properties.etag, null)
}

output "default_encryption_scope" {
  description = "The default encryption scope applied to blobs in this container."
  value       = try(rest_resource.container.output.properties.defaultEncryptionScope, null)
}

output "has_legal_hold" {
  description = "Whether the container has a legal hold tag applied."
  value       = try(rest_resource.container.output.properties.hasLegalHold, null)
}

output "has_immutability_policy" {
  description = "Whether the container has an immutability policy configured."
  value       = try(rest_resource.container.output.properties.hasImmutabilityPolicy, null)
}

output "lease_status" {
  description = "The container lease status (Locked or Unlocked)."
  value       = try(rest_resource.container.output.properties.leaseStatus, null)
}

output "lease_state" {
  description = "The container lease state (Available, Leased, Expired, Breaking, Broken)."
  value       = try(rest_resource.container.output.properties.leaseState, null)
}

output "last_modified_time" {
  description = "The date and time the container was last modified."
  value       = try(rest_resource.container.output.properties.lastModifiedTime, null)
}
