locals {
  _entraid_values = { for k, v in {
    entraid_applications             = module.entraid_applications
    entraid_groups                   = module.entraid_groups
    entraid_users                    = module.entraid_users
    entraid_group_members            = module.entraid_group_members
    entraid_service_principals       = module.entraid_service_principals
    entraid_app_role_assignments     = module.entraid_app_role_assignments
    entraid_oauth2_permission_grants = module.entraid_oauth2_permission_grants
  } : k => v if length(v) > 0 }
}

output "entraid_values" {
  description = "Map of all Entra ID module outputs, keyed by the same keys as var.*. Empty maps are filtered out."
  value       = length(local._entraid_values) > 0 ? local._entraid_values : null
}
