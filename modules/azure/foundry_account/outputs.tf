# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "id" {
  description = "The full ARM resource ID of the Foundry account (plan-time)."
  value       = local.account_path
}

output "api_version" {
  description = "The ARM API version used to manage this resource."
  value       = local.api_version
}

output "account_name" {
  description = "The name of the Foundry account (plan-time, echoes input)."
  value       = var.account_name
}

output "location" {
  description = "The Azure region of the Foundry account (plan-time, echoes input)."
  value       = var.location
}

output "resource_group_name" {
  description = "The resource group name (plan-time, echoes input)."
  value       = var.resource_group_name
}

output "kind" {
  description = "The kind of the Foundry account (plan-time, echoes input)."
  value       = var.kind
}

output "sku_name" {
  description = "The SKU name of the Foundry account (plan-time, echoes input)."
  value       = var.sku_name
}

# ── Known after apply ─────────────────────────────────────────────────────────

output "provisioning_state" {
  description = "The provisioning state of the Foundry account (e.g. Succeeded)."
  value       = try(rest_resource.foundry_account.output.properties.provisioningState, null)
}

output "endpoint" {
  description = "The HTTPS endpoint URL of the Foundry account (e.g. https://my-foundry.cognitiveservices.azure.com/)."
  value       = try(rest_resource.foundry_account.output.properties.endpoint, null)
}

output "internal_id" {
  description = "The internal Azure-assigned account ID."
  value       = try(rest_resource.foundry_account.output.properties.internalId, null)
}

output "date_created" {
  description = "The UTC timestamp when the Foundry account was created."
  value       = try(rest_resource.foundry_account.output.properties.dateCreated, null)
}

output "principal_id" {
  description = "The principal (object) ID of the system-assigned managed identity. Null if identity_type is not SystemAssigned."
  value       = try(rest_resource.foundry_account.output.identity.principalId, null)
}

output "tenant_id_identity" {
  description = "The tenant ID of the system-assigned managed identity."
  value       = try(rest_resource.foundry_account.output.identity.tenantId, null)
}
