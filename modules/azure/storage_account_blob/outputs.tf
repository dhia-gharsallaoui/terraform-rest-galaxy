# ── Plan-time known outputs (derived from input variables) ─────────────────────

output "id" {
  description = "The data-plane path of the blob: /{containerName}/{blobName}. Suitable as a unique identifier within the storage account."
  value       = local.blob_path
}

output "api_version" {
  description = "The Blob Storage data-plane API version used to manage this blob."
  value       = local.api_version
}

output "name" {
  description = "The blob name (path within the container). Plan-time known, echoes input."
  value       = var.blob_name
}

output "container_name" {
  description = "The container name that holds this blob. Plan-time known, echoes input."
  value       = var.container_name
}

output "account_name" {
  description = "The storage account name. Plan-time known, echoes input."
  value       = var.account_name
}

output "blob_url" {
  description = "The full data-plane URL of the blob (plan-time, computed from inputs)."
  value       = "https://${var.account_name}.blob.core.windows.net/${var.container_name}/${var.blob_name}"
}

# ── API-sourced outputs (known after apply) ────────────────────────────────────

output "etag" {
  description = "The ETag of the blob, returned by the PUT response. Known after apply."
  value       = try(rest_resource.blob.output.ETag, null)
}

output "last_modified" {
  description = "The last-modified timestamp of the blob. Known after apply."
  value       = try(rest_resource.blob.output["Last-Modified"], null)
}

output "version_id" {
  description = "The blob version ID (only populated when blob versioning is enabled on the storage account). Known after apply."
  value       = try(rest_resource.blob.output["x-ms-version-id"], null)
}

output "server_encrypted" {
  description = "Whether the blob contents are server-encrypted. Known after apply."
  value       = try(rest_resource.blob.output["x-ms-request-server-encrypted"], null)
}
