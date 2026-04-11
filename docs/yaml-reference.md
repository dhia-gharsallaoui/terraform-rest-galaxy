# YAML Configuration Reference

All resources that can be created with terraform-rest-galaxy are declared in YAML
configuration files. Each top-level key maps directly to a Terraform variable name.

Values prefixed with `ref:` are resolved at plan time against the reference context:

```yaml
resource_group_name: ref:azure_resource_groups.app.resource_group_name
location:           ref:azure_resource_groups.app.location
```

---

## Providers


### [Azure](yaml-reference-azure.md) — 71 resources

  - [`azure_app_service_domains`](yaml-reference-azure.md#azure-app-service-domains)
  - [`azure_arc_connected_clusters`](yaml-reference-azure.md#azure-arc-connected-clusters)
  - [`azure_arc_kubernetes_extensions`](yaml-reference-azure.md#azure-arc-kubernetes-extensions)
  - [`azure_billing_associated_tenants`](yaml-reference-azure.md#azure-billing-associated-tenants)
  - [`azure_billing_permission_requests`](yaml-reference-azure.md#azure-billing-permission-requests)
  - [`azure_billing_role_assignments`](yaml-reference-azure.md#azure-billing-role-assignments)
  - [`azure_ciam_directories`](yaml-reference-azure.md#azure-ciam-directories)
  - [`azure_communication_services`](yaml-reference-azure.md#azure-communication-services)
  - [`azure_container_registries`](yaml-reference-azure.md#azure-container-registries)
  - [`azure_container_registry_imports`](yaml-reference-azure.md#azure-container-registry-imports)
  - [`azure_dns_record_sets`](yaml-reference-azure.md#azure-dns-record-sets)
  - [`azure_dns_resolvers`](yaml-reference-azure.md#azure-dns-resolvers)
  - [`azure_dns_zones`](yaml-reference-azure.md#azure-dns-zones)
  - [`azure_email_communication_service_domains`](yaml-reference-azure.md#azure-email-communication-service-domains)
  - [`azure_email_communication_services`](yaml-reference-azure.md#azure-email-communication-services)
  - [`azure_express_route_circuit_peerings`](yaml-reference-azure.md#azure-express-route-circuit-peerings)
  - [`azure_express_route_circuits`](yaml-reference-azure.md#azure-express-route-circuits)
  - [`azure_express_route_ports`](yaml-reference-azure.md#azure-express-route-ports)
  - [`azure_federated_identity_credentials`](yaml-reference-azure.md#azure-federated-identity-credentials)
  - [`azure_firewall_policies`](yaml-reference-azure.md#azure-firewall-policies)
  - [`azure_firewalls`](yaml-reference-azure.md#azure-firewalls)
  - [`azure_foundry_accounts`](yaml-reference-azure.md#azure-foundry-accounts)
  - [`azure_foundry_deployments`](yaml-reference-azure.md#azure-foundry-deployments)
  - [`azure_foundry_managed_networks`](yaml-reference-azure.md#azure-foundry-managed-networks)
  - [`azure_github_network_settings`](yaml-reference-azure.md#azure-github-network-settings)
  - [`azure_ipam_pools`](yaml-reference-azure.md#azure-ipam-pools)
  - [`azure_ipam_static_cidrs`](yaml-reference-azure.md#azure-ipam-static-cidrs)
  - [`azure_key_vault_keys`](yaml-reference-azure.md#azure-key-vault-keys)
  - [`azure_key_vaults`](yaml-reference-azure.md#azure-key-vaults)
  - [`azure_load_balancers`](yaml-reference-azure.md#azure-load-balancers)
  - [`azure_managed_clusters`](yaml-reference-azure.md#azure-managed-clusters)
  - [`azure_management_locks`](yaml-reference-azure.md#azure-management-locks)
  - [`azure_network_interfaces`](yaml-reference-azure.md#azure-network-interfaces)
  - [`azure_network_managers`](yaml-reference-azure.md#azure-network-managers)
  - [`azure_postgresql_flexible_server_administrators`](yaml-reference-azure.md#azure-postgresql-flexible-server-administrators)
  - [`azure_postgresql_flexible_servers`](yaml-reference-azure.md#azure-postgresql-flexible-servers)
  - [`azure_private_dns_zones`](yaml-reference-azure.md#azure-private-dns-zones)
  - [`azure_private_endpoints`](yaml-reference-azure.md#azure-private-endpoints)
  - [`azure_public_ip_addresses`](yaml-reference-azure.md#azure-public-ip-addresses)
  - [`azure_redis_enterprise_clusters`](yaml-reference-azure.md#azure-redis-enterprise-clusters)
  - [`azure_redis_enterprise_databases`](yaml-reference-azure.md#azure-redis-enterprise-databases)
  - [`azure_resource_groups`](yaml-reference-azure.md#azure-resource-groups)
  - [`azure_resource_provider_features`](yaml-reference-azure.md#azure-resource-provider-features)
  - [`azure_resource_provider_registrations`](yaml-reference-azure.md#azure-resource-provider-registrations)
  - [`azure_role_assignments`](yaml-reference-azure.md#azure-role-assignments)
  - [`azure_role_assignments_post`](yaml-reference-azure.md#azure-role-assignments-post)
  - [`azure_route_tables`](yaml-reference-azure.md#azure-route-tables)
  - [`azure_routing_intents`](yaml-reference-azure.md#azure-routing-intents)
  - [`azure_storage_account_blob_services`](yaml-reference-azure.md#azure-storage-account-blob-services)
  - [`azure_storage_account_blobs`](yaml-reference-azure.md#azure-storage-account-blobs)
  - [`azure_storage_account_containers`](yaml-reference-azure.md#azure-storage-account-containers)
  - [`azure_storage_account_encryption_scopes`](yaml-reference-azure.md#azure-storage-account-encryption-scopes)
  - [`azure_storage_account_file_services`](yaml-reference-azure.md#azure-storage-account-file-services)
  - [`azure_storage_account_file_shares`](yaml-reference-azure.md#azure-storage-account-file-shares)
  - [`azure_storage_account_inventory_policies`](yaml-reference-azure.md#azure-storage-account-inventory-policies)
  - [`azure_storage_account_local_users`](yaml-reference-azure.md#azure-storage-account-local-users)
  - [`azure_storage_account_management_policies`](yaml-reference-azure.md#azure-storage-account-management-policies)
  - [`azure_storage_account_object_replication_policies`](yaml-reference-azure.md#azure-storage-account-object-replication-policies)
  - [`azure_storage_account_queues`](yaml-reference-azure.md#azure-storage-account-queues)
  - [`azure_storage_account_tables`](yaml-reference-azure.md#azure-storage-account-tables)
  - [`azure_storage_accounts`](yaml-reference-azure.md#azure-storage-accounts)
  - [`azure_subscriptions`](yaml-reference-azure.md#azure-subscriptions)
  - [`azure_user_assigned_identities`](yaml-reference-azure.md#azure-user-assigned-identities)
  - [`azure_virtual_hub_connections`](yaml-reference-azure.md#azure-virtual-hub-connections)
  - [`azure_virtual_hubs`](yaml-reference-azure.md#azure-virtual-hubs)
  - [`azure_virtual_network_gateway_connections`](yaml-reference-azure.md#azure-virtual-network-gateway-connections)
  - [`azure_virtual_network_gateways`](yaml-reference-azure.md#azure-virtual-network-gateways)
  - [`azure_virtual_network_peerings`](yaml-reference-azure.md#azure-virtual-network-peerings)
  - [`azure_virtual_networks`](yaml-reference-azure.md#azure-virtual-networks)
  - [`azure_virtual_wans`](yaml-reference-azure.md#azure-virtual-wans)
  - [`azure_vpn_gateways`](yaml-reference-azure.md#azure-vpn-gateways)

### [Entra ID](yaml-reference-entraid.md) — 7 resources

  - [`entraid_app_role_assignments`](yaml-reference-entraid.md#entraid-app-role-assignments)
  - [`entraid_applications`](yaml-reference-entraid.md#entraid-applications)
  - [`entraid_group_members`](yaml-reference-entraid.md#entraid-group-members)
  - [`entraid_groups`](yaml-reference-entraid.md#entraid-groups)
  - [`entraid_oauth2_permission_grants`](yaml-reference-entraid.md#entraid-oauth2-permission-grants)
  - [`entraid_service_principals`](yaml-reference-entraid.md#entraid-service-principals)
  - [`entraid_users`](yaml-reference-entraid.md#entraid-users)

### [GitHub](yaml-reference-github.md) — 7 resources

  - [`github_environment_secrets`](yaml-reference-github.md#github-environment-secrets)
  - [`github_environments`](yaml-reference-github.md#github-environments)
  - [`github_hosted_runners`](yaml-reference-github.md#github-hosted-runners)
  - [`github_organization_secrets`](yaml-reference-github.md#github-organization-secrets)
  - [`github_repositories`](yaml-reference-github.md#github-repositories)
  - [`github_repository_secrets`](yaml-reference-github.md#github-repository-secrets)
  - [`github_runner_groups`](yaml-reference-github.md#github-runner-groups)

### [Kubernetes](yaml-reference-k8s.md) — 7 resources

  - [`k8s_cluster_role_bindings`](yaml-reference-k8s.md#k8s-cluster-role-bindings)
  - [`k8s_config_maps`](yaml-reference-k8s.md#k8s-config-maps)
  - [`k8s_deployments`](yaml-reference-k8s.md#k8s-deployments)
  - [`k8s_jobs`](yaml-reference-k8s.md#k8s-jobs)
  - [`k8s_kind_clusters`](yaml-reference-k8s.md#k8s-kind-clusters)
  - [`k8s_namespaces`](yaml-reference-k8s.md#k8s-namespaces)
  - [`k8s_service_accounts`](yaml-reference-k8s.md#k8s-service-accounts)
