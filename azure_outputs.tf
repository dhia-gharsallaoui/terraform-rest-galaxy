output "azure_values" {
  description = "Map of all Azure module outputs, keyed by the same keys as var.*. Empty maps are filtered out."
  value = { for k, v in {
    azure_subscriptions                             = module.azure_subscriptions
    azure_resource_groups                           = module.azure_resource_groups
    azure_user_assigned_identities                  = module.azure_user_assigned_identities
    azure_key_vaults                                = module.azure_key_vaults
    azure_key_vault_keys                            = module.azure_key_vault_keys
    azure_role_assignments                          = module.azure_role_assignments
    azure_resource_provider_registrations           = module.azure_resource_provider_registrations
    azure_resource_provider_features                = module.azure_resource_provider_features
    azure_storage_accounts                          = module.azure_storage_accounts
    azure_virtual_wans                              = module.azure_virtual_wans
    azure_virtual_networks                          = module.azure_virtual_networks
    azure_virtual_hubs                              = module.azure_virtual_hubs
    azure_virtual_network_gateways                  = module.azure_virtual_network_gateways
    azure_firewall_policies                         = module.azure_firewall_policies
    azure_firewalls                                 = module.azure_firewalls
    azure_routing_intents                           = module.azure_routing_intents
    azure_route_tables                              = module.azure_route_tables
    azure_public_ip_addresses                       = module.azure_public_ip_addresses
    azure_load_balancers                            = module.azure_load_balancers
    azure_network_interfaces                        = module.azure_network_interfaces
    azure_private_endpoints                         = module.azure_private_endpoints
    azure_virtual_network_gateway_connections       = module.azure_virtual_network_gateway_connections
    azure_express_route_circuits                    = module.azure_express_route_circuits
    azure_express_route_ports                       = module.azure_express_route_ports
    azure_vpn_gateways                              = module.azure_vpn_gateways
    azure_virtual_hub_connections                   = module.azure_virtual_hub_connections
    azure_express_route_circuit_peerings            = module.azure_express_route_circuit_peerings
    azure_ciam_directories                          = module.azure_ciam_directories
    azure_redis_enterprise_clusters                 = module.azure_redis_enterprise_clusters
    azure_redis_enterprise_databases                = module.azure_redis_enterprise_databases
    azure_private_dns_zones                         = module.azure_private_dns_zones
    azure_network_managers                          = module.azure_network_managers
    azure_ipam_pools                                = module.azure_ipam_pools
    azure_ipam_static_cidrs                         = module.azure_ipam_static_cidrs
    azure_billing_associated_tenants                = module.azure_billing_associated_tenants
    azure_billing_role_assignments                  = module.azure_billing_role_assignments
    azure_billing_permission_requests               = module.azure_billing_permission_requests
    azure_arc_connected_clusters                    = module.azure_arc_connected_clusters
    azure_arc_kubernetes_extensions                 = module.azure_arc_kubernetes_extensions
    azure_management_locks                          = module.azure_management_locks
    azure_storage_account_containers                = module.azure_storage_account_containers
    azure_dns_resolvers                             = module.azure_dns_resolvers
    azure_container_registries                      = module.azure_container_registries
    azure_container_registry_imports                = module.azure_container_registry_imports
    azure_managed_clusters                          = module.azure_managed_clusters
    azure_postgresql_flexible_servers               = module.azure_postgresql_flexible_servers
    azure_postgresql_flexible_server_administrators = module.azure_postgresql_flexible_server_administrators
    azure_virtual_network_peerings                  = module.azure_virtual_network_peerings
    azure_federated_identity_credentials            = module.azure_federated_identity_credentials
    azure_github_network_settings                   = module.azure_github_network_settings
    azure_email_communication_services              = module.azure_email_communication_services
    azure_email_communication_service_domains       = module.azure_email_communication_service_domains
    azure_communication_services                    = module.azure_communication_services
    azure_app_service_domains                       = module.azure_app_service_domains
    azure_dns_zones                                 = module.azure_dns_zones
    azure_dns_record_sets                           = module.azure_dns_record_sets
  } : k => v if length(v) > 0 }
}

output "github_values" {
  description = "Map of all GitHub module outputs, keyed by the same keys as var.*. Empty maps are filtered out."
  value = length(local._github_values) > 0 ? local._github_values : null
}

locals {
  _github_values = { for k, v in {
    github_runner_groups               = module.github_runner_groups
    github_hosted_runners              = module.github_hosted_runners
    github_repositories                = module.github_repositories
    github_repository_action_variables = module.github_repository_action_variables
    github_repository_secrets          = module.github_repository_secrets
    github_environments                = module.github_environments
    github_environment_secrets         = module.github_environment_secrets
    github_environment_variables       = module.github_environment_variables
    github_organization_secrets        = module.github_organization_secrets
    github_organization_variables      = module.github_organization_variables
  } : k => v if length(v) > 0 }
}

locals {
  _externals_output = { for k, v in local._externals : k => v if length(v) > 0 }
}

output "externals" {
  description = "Validated external references (not managed by Terraform). Empty categories are filtered out."
  value       = length(local._externals_output) > 0 ? local._externals_output : null
}