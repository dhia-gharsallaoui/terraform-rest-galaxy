# Plan-time known — echoes input variable path
output "id" {
  description = "The full ARM resource ID of the file share."
  value       = local.share_path
}

# Plan-time known — echoes input variable
output "name" {
  description = "The file share name (plan-time, echoes input)."
  value       = var.share_name
}

output "api_version" {
  description = "The ARM API version used to manage this file share."
  value       = local.api_version
}

# API-sourced outputs — known after apply
output "provisioning_state" {
  description = "The provisioning state of the file share."
  value       = try(rest_resource.file_share.output.properties.provisioningState, null)
}

output "enabled_protocols" {
  description = "The authentication protocol of the file share (SMB or NFS)."
  value       = try(rest_resource.file_share.output.properties.enabledProtocols, null)
}

output "access_tier" {
  description = "The effective access tier of the file share."
  value       = try(rest_resource.file_share.output.properties.accessTier, null)
}

output "share_quota" {
  description = "The provisioned size of the file share in gibibytes."
  value       = try(rest_resource.file_share.output.properties.shareQuota, null)
}
