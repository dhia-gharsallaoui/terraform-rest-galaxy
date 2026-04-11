# Plan-time known — echoes input variable path
output "id" {
  description = "The full ARM resource ID of the storage queue."
  value       = local.queue_path
}

# Plan-time known — echoes input variable
output "name" {
  description = "The queue name (plan-time, echoes input)."
  value       = var.queue_name
}

output "api_version" {
  description = "The ARM API version used to manage this queue."
  value       = local.api_version
}

# API-sourced outputs — known after apply
output "approximate_message_count" {
  description = "An approximate count of messages in the queue. Not lower than actual count but may be higher."
  value       = try(rest_resource.queue.output.properties.approximateMessageCount, null)
}
