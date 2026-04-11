# ── Plan-time known (echoes input) ────────────────────────────────────────────

output "id" {
  description = "The full ARM resource ID of the managed network (plan-time)."
  value       = local.managed_network_path
}

output "api_version" {
  description = "The ARM API version used to manage this resource."
  value       = local.api_version
}

output "account_name" {
  description = "The parent Foundry account name (plan-time, echoes input)."
  value       = var.account_name
}

output "resource_group_name" {
  description = "The resource group name (plan-time, echoes input)."
  value       = var.resource_group_name
}

output "isolation_mode" {
  description = "The managed network isolation mode (plan-time, echoes input)."
  value       = var.isolation_mode
}

output "managed_network_kind" {
  description = "The managed network kind: V1 or V2 (plan-time, echoes input)."
  value       = var.managed_network_kind
}

# ── Known after apply ─────────────────────────────────────────────────────────

output "provisioning_state" {
  description = "The provisioning state of the managed network (e.g. Succeeded)."
  value       = try(rest_operation.foundry_managed_network.output.properties.provisioningState, null)
}

output "network_isolation_mode" {
  description = "The isolation mode as confirmed by Azure after apply."
  value       = try(rest_operation.foundry_managed_network.output.properties.managedNetwork.isolationMode, null)
}

output "network_kind" {
  description = "The managed network kind as confirmed by Azure after apply."
  value       = try(rest_operation.foundry_managed_network.output.properties.managedNetwork.managedNetworkKind, null)
}

output "firewall_sku" {
  description = "The firewall SKU as confirmed by Azure after apply."
  value       = try(rest_operation.foundry_managed_network.output.properties.managedNetwork.firewallSku, null)
}

output "network_status" {
  description = "The managed network provisioning status: Active or Inactive."
  value       = try(rest_operation.foundry_managed_network.output.properties.managedNetwork.status.status, null)
}
