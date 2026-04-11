# Plan-time outputs — derived from input variables.

output "id" {
  description = "The full ARM resource ID of the object replication policy."
  value       = local.policy_path
}

output "api_version" {
  description = "The ARM API version used to manage this object replication policy."
  value       = "2025-08-01"
}

# API-sourced outputs — assigned by Azure at creation time.

output "policy_id" {
  description = "The unique policy ID assigned by Azure. Use this value for subsequent updates and for configuring the corresponding source-account policy."
  value       = try(rest_resource.object_replication_policy.output.properties.policyId, null)
}

output "enabled_time" {
  description = "The datetime when the policy was enabled on the source account."
  value       = try(rest_resource.object_replication_policy.output.properties.enabledTime, null)
}

output "rules" {
  description = "The replication rules with auto-assigned ruleId values. Use these ruleId values when configuring the source-account policy."
  value       = try(rest_resource.object_replication_policy.output.properties.rules, null)
}
