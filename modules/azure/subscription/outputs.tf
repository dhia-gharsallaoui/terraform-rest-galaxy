# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "id" {
  description = "The full ARM resource ID of the subscription alias."
  value       = local.alias_path
}

output "alias_name" {
  description = "The alias name (echoes input)."
  value       = var.alias_name
}

output "display_name" {
  description = "The display name of the subscription (echoes input)."
  value       = var.display_name
}

# ── Known after apply (Azure-assigned) ────────────────────────────────────────

output "subscription_id" {
  description = "The Azure subscription ID created or associated with this alias."
  value       = try(rest_resource.subscription.output.properties.subscriptionId, null)
}

output "provisioning_state" {
  description = "The provisioning state of the subscription alias."
  value       = try(rest_resource.subscription.output.properties.provisioningState, null)
}

output "scope" {
  description = "The subscription-scoped ARM path (/subscriptions/{subscription_id}), known after apply. Use as the scope input for subscription-level role assignments."
  value       = try("/subscriptions/${rest_resource.subscription.output.properties.subscriptionId}", null)
}
