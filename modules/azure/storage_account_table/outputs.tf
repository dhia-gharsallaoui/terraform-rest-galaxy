# Plan-time known — echoes input variable path
output "id" {
  description = "The full ARM resource ID of the storage table."
  value       = local.table_path
}

# Plan-time known — echoes input variable
output "name" {
  description = "The table name (plan-time, echoes input)."
  value       = var.table_name
}

output "api_version" {
  description = "The ARM API version used to manage this table."
  value       = local.api_version
}

# API-sourced outputs — known after apply
output "table_name_from_api" {
  description = "The table name as returned by the Azure API (known after apply)."
  value       = try(rest_resource.table.output.properties.tableName, null)
}
