# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "id" {
  description = "The full ARM resource ID of the deployment (plan-time)."
  value       = local.deployment_path
}

output "api_version" {
  description = "The ARM API version used to manage this resource."
  value       = local.api_version
}

output "deployment_name" {
  description = "The name of the deployment (plan-time, echoes input)."
  value       = var.deployment_name
}

output "account_name" {
  description = "The parent Foundry account name (plan-time, echoes input)."
  value       = var.account_name
}

output "resource_group_name" {
  description = "The resource group name (plan-time, echoes input)."
  value       = var.resource_group_name
}

output "location" {
  description = "The Azure region (plan-time, echoes input)."
  value       = var.location
}

output "model_name" {
  description = "The deployed model name (plan-time, echoes input)."
  value       = var.model_name
}

output "model_format" {
  description = "The deployed model format (plan-time, echoes input)."
  value       = var.model_format
}

output "sku_name" {
  description = "The deployment SKU name (plan-time, echoes input)."
  value       = var.sku_name
}

# ── Known after apply ─────────────────────────────────────────────────────────

output "provisioning_state" {
  description = "The provisioning state of the deployment (e.g. Succeeded)."
  value       = try(rest_resource.foundry_deployment.output.properties.provisioningState, null)
}

output "model_version_deployed" {
  description = "The actual model version deployed (may differ from input if version was null — Azure selects the default)."
  value       = try(rest_resource.foundry_deployment.output.properties.model.version, null)
}

output "version_upgrade_option" {
  description = "The version upgrade option as confirmed by Azure after apply."
  value       = try(rest_resource.foundry_deployment.output.properties.versionUpgradeOption, null)
}

output "sku_capacity_deployed" {
  description = "The actual capacity allocated by Azure after apply."
  value       = try(rest_resource.foundry_deployment.output.sku.capacity, null)
}
