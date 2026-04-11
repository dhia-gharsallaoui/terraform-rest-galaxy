# YAML Reference — Azure

← [Back to index](yaml-reference.md)

### `azure_app_service_domains`

**API version:** `2024-11-01`

Map of App Service Domains (domain purchases) to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `domain_name` | `string` | yes | — |  |
| `location` | `string` | no | `"global"` |  |
| `contact_admin` | `object` | yes | — |  |
| `contact_billing` | `object` | yes | — |  |
| `contact_registrant` | `object` | yes | — |  |
| `contact_tech` | `object` | yes | — |  |
| `consent_agreed_by` | `string` | yes | — |  |
| `consent_agreed_at` | `string` | yes | — |  |
| `consent_agreement_keys` | `list(string)` | no | `[]` |  |
| `privacy` | `bool` | no | `true` |  |
| `auto_renew` | `bool` | no | `true` |  |
| `dns_type` | `string` | no | `"AzureDns"` |  |
| `dns_zone_id` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_app_service_domains:
  contoso:
    resource_group_name: "rg-dns"
    domain_name: "contoso.com"
    contact_admin:
      first_name: "John"
      last_name: "Doe"
      email: "admin@contoso.com"
      phone: "+1.5551234567"
    contact_billing:
      first_name: "John"
      last_name: "Doe"
      email: "billing@contoso.com"
      phone: "+1.5551234567"
    contact_registrant:
      first_name: "John"
      last_name: "Doe"
      email: "registrant@contoso.com"
      phone: "+1.5551234567"
    contact_tech:
      first_name: "John"
      last_name: "Doe"
      email: "tech@contoso.com"
      phone: "+1.5551234567"
    consent_agreed_by: "203.0.113.10"
    consent_agreed_at: "2026-01-01T00:00:00Z"
```

---

### `azure_arc_connected_clusters`

**API version:** `2024-01-01`

Map of Azure Arc connected clusters to register. Each map key acts as the
for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `cluster_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` |  |
| `identity_type` | `string` | no | `"SystemAssigned"` |  |
| `agent_public_key_certificate` | `string` | no | `""` |  |
| `kind` | `string` | no | `null` |  |
| `distribution` | `string` | no | `null` |  |
| `distribution_version` | `string` | no | `null` |  |
| `infrastructure` | `string` | no | `null` |  |
| `private_link_state` | `string` | no | `null` |  |
| `private_link_scope_resource_id` | `string` | no | `null` |  |
| `azure_hybrid_benefit` | `string` | no | `null` |  |
| `aad_profile` | `object` | no | `null` |  |
| `arc_agent_profile` | `object` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |
| `_tenant` | `string` | no | `null` |  |
| `wait_for_connection` | `bool` | no | `true` |  |

#### YAML Example

```yaml
azure_arc_connected_clusters:
  platform:
    subscription_id: "00000000-..."
    resource_group_name: "rg-arc"
    cluster_name: "platform-cluster"
    location: "westeurope"
    agent_public_key_certificate: "<base64-encoded-public-key>"
    distribution: "kind"
    aad_profile:
      enable_azure_rbac: true
      admin_group_object_ids: ["00000000-..."]
```

---

### `azure_arc_kubernetes_extensions`

**API version:** `2025-03-01`

Map of Azure Arc Kubernetes extensions to install on connected/managed clusters.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | `null` |  |
| `resource_group_name` | `string` | yes | — |  |
| `cluster_rp` | `string` | no | `"Microsoft.Kubernetes"` |  |
| `cluster_resource_name` | `string` | no | `"connectedClusters"` |  |
| `cluster_name` | `string` | yes | — |  |
| `extension_name` | `string` | yes | — |  |
| `extension_type` | `string` | yes | — |  |
| `auto_upgrade_minor_version` | `bool` | no | `true` |  |
| `release_train` | `string` | no | `null` |  |
| `version_pin` | `string` | no | `null` |  |
| `scope` | `object` | no | `null` |  |
| `configuration_settings` | `map(string)` | no | `null` |  |
| `configuration_protected_settings` | `map(string)` | no | `null` |  |
| `identity_type` | `string` | no | `null` |  |
| `plan` | `object` | no | `null` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_arc_kubernetes_extensions:
  monitor_edge:
    resource_group_name: "rg-arc-clusters"
    cluster_name: "edge-cluster"
    extension_name: "azuremonitor-pipeline"
    extension_type: "microsoft.monitor.pipelinecontroller"
```

---

### `azure_billing_associated_tenants`

**API version:** `2024-04-01`

Map of associated billing tenants to create or manage. Each map key acts as
the for_each identifier and must be unique within this configuration.

Requires a Microsoft Customer Agreement – Enterprise billing account.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `billing_account_name` | `string` | yes | — |  |
| `tenant_id` | `string` | yes | — |  |
| `display_name` | `string` | yes | — |  |
| `billing_management_state` | `string` | no | `"Active"` |  |
| `provisioning_management_state` | `string` | no | `"NotRequested"` |  |
| `precheck_access` | `bool` | no | `null` | null → inherits from var.precheck_billing_access |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_billing_associated_tenants:
  partner:
    billing_account_name: "12345678:12345678-1234-1234-1234-123456789012_2024-01-01"
    tenant_id: "aaaabbbb-cccc-dddd-eeee-ffffgggggggg"
    display_name: "Partner Tenant"
    billing_management_state: "Active"
    provisioning_management_state: "Pending"
```

---

### `azure_billing_permission_requests`

**API version:** `2020-11-01-privatepreview`

Map of billing permission/request approvals. Each map key acts as the
for_each identifier.

Exactly one of associated_tenant or billing_request_id must be set:

associated_tenant — key into azure_billing_associated_tenants whose
provisioningBillingRequestId will be approved via the permissionRequests
private-preview API. _tenant should be the TARGET tenant.

billing_request_id — the GUID of a billingRequest to approve via the
GA billingRequests API (2024-04-01). Used for invoice-section-scoped
role assignment requests. _tenant should be the BILLING tenant
(approval requires invoice section owner permissions).
Get the GUID from the first apply output or the Azure portal.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `associated_tenant` | `string` | no | `null` |  |
| `billing_request_id` | `string` | no | `null` |  |
| `status` | `string` | no | `"Approved"` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_billing_permission_requests:
  approve_partner:
    associated_tenant: "partner"
    status: "Approved"
    _tenant: "target-tenant-id"
  approve_role:
    billing_request_id: "895fb3ca-5ba7-40d0-a6a1-b4601518d564"
    status: "Approved"
    _tenant: "billing-tenant-id"
```

---

### `azure_billing_role_assignments`

**API version:** `2024-04-01`

Map of billing role assignments to create. Each map key acts as the for_each
identifier. Use this to grant billing-level roles (owner, contributor, reader)
to identities that need access to billing accounts, profiles, or invoice sections.

The role_definition_id can be a full path or just the GUID:
  Full:  /providers/Microsoft.Billing/billingAccounts/{name}/billingRoleDefinitions/{guid}
  GUID:  10000000-aaaa-bbbb-cccc-100000000002

Common billing role definition names:
  - Billing account owner
  - Billing account contributor
  - Billing account reader
  - Signatory

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `billing_account_name` | `string` | yes | — |  |
| `billing_scope` | `string` | no | `null` |  |
| `principal_id` | `string` | yes | — |  |
| `principal_tenant_id` | `string` | yes | — |  |
| `role_definition_id` | `string` | yes | — |  |
| `principal_type` | `string` | no | `"ServicePrincipal"` |  |
| `user_email_address` | `string` | no | `null` |  |
| `billing_request_id` | `string` | no | `null` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_billing_role_assignments:
  reader:
    billing_account_name: "12345678-...:12345678-..._2019-05-31"
    principal_id: "00000000-0000-0000-0000-000000000000"
    principal_tenant_id: "00000000-0000-0000-0000-000000000000"
    role_definition_id: "/providers/Microsoft.Billing/billingAccounts/.../billingRoleDefinitions/..."
    principal_type: "User"
```

---

### `azure_ciam_directories`

**API version:** `2023-05-17-preview`

Map of Azure AD for customers (CIAM) directories to create. Each map key
acts as the for_each identifier and must be unique within this configuration.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `resource_name` | `string` | yes | — |  |
| `location` | `string` | yes | — |  |
| `display_name` | `string` | yes | — |  |
| `country_code` | `string` | yes | — |  |
| `sku_name` | `string` | no | `"Standard"` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_ciam_directories:
  customer_portal:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-identity-prod"
    resource_name: "myappciamprod"
    location: "Europe"
    display_name: "My App Customer Portal"
    country_code: "FR"
```

---

### `azure_communication_services`

**API version:** `2026-03-18`

Map of Communication Services to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `communication_service_name` | `string` | yes | — |  |
| `location` | `string` | no | `"global"` |  |
| `data_location` | `string` | no | `"Europe"` |  |
| `linked_domains` | `list(string)` | no | `null` |  |
| `public_network_access` | `string` | no | `null` |  |
| `disable_local_auth` | `bool` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_communication_services:
  main:
    resource_group_name: "rg-acs"
    communication_service_name: "acs-main"
    location: "global"
    data_location: "Europe"
    linked_domains: ["ref:azure_email_communication_service_domains.azure_managed.id"]
```

---

### `azure_container_registries`

**API version:** `2025-11-01`

Map of Azure Container Registries to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `registry_name` | `string` | yes | — |  |
| `sku_name` | `string` | no | `"Basic"` |  |
| `location` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |
| `admin_user_enabled` | `bool` | no | `false` |  |
| `public_network_access` | `string` | no | `null` |  |
| `anonymous_pull_enabled` | `bool` | no | `null` |  |

#### YAML Example

```yaml
azure_container_registries:
  arc:
    resource_group_name: "ref:azure_resource_groups.arc.resource_group_name"
    registry_name: "myacrforarcagents"
    sku_name: "Basic"
    location: "westeurope"
```

---

### `azure_container_registry_imports`

**API version:** `2025-11-01`

Map of images to import into Azure Container Registries.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `registry_name` | `string` | yes | — |  |
| `source_registry_uri` | `string` | yes | — |  |
| `source_image` | `string` | yes | — |  |
| `target_tags` | `list(string)` | no | `null` |  |
| `mode` | `string` | no | `"Force"` |  |

#### YAML Example

```yaml
azure_container_registry_imports:
  arc_chart:
    resource_group_name: "ref:azure_resource_groups.arc.resource_group_name"
    registry_name: "ref:azure_container_registries.arc.registry_name"
    source_registry_uri: "mcr.microsoft.com"
    source_image: "azurearck8s/batch1/stable/azure-arc-k8sagents:1.33.0"
```

---

### `azure_dns_record_sets`

**API version:** `2018-05-01`

Map of Azure DNS record sets to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `zone_name` | `string` | yes | — |  |
| `record_name` | `string` | yes | — |  |
| `record_type` | `string` | yes | — |  |
| `ttl` | `number` | no | `3600` |  |
| `txt_records` | `list(object)` | no | `null` |  |
| `cname_record` | `object` | no | `null` |  |
| `mx_records` | `list(object)` | no | `null` |  |
| `a_records` | `list(object)` | no | `null` |  |
| `aaaa_records` | `list(object)` | no | `null` |  |
| `metadata` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_dns_record_sets:
  spf:
    resource_group_name: "rg-dns"
    zone_name: "contoso.com"
    record_name: "@"
    record_type: "TXT"
    ttl: 3600
    txt_records: [{ value = ["v=spf1 include:spf.protection.outlook.com -all"] }]
```

---

### `azure_dns_resolvers`

**API version:** `2025-05-01`

Map of Azure Private DNS Resolvers to create via ARM REST API.
Each resolver is attached to a virtual network and can have inbound
endpoints for receiving DNS queries (e.g. from VPN clients).

Inbound endpoints require a dedicated subnet (min /28) with delegation
to Microsoft.Network/dnsResolvers.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `dns_resolver_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `virtual_network_id` | `string` | yes | — |  |
| `inbound_endpoints` | `list(object)` | no | `[]` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_dns_resolvers:
  hub:
    resource_group_name: "ref:azure_resource_groups.launchpad.resource_group_name"
    dns_resolver_name: "dnspr-hub-launchpad"
    virtual_network_id: "ref:azure_virtual_networks.hub.id"
    inbound_endpoints: [
        name: "inbound"
        subnet_id: "ref:azure_virtual_networks.hub.subnet_ids.snet-dns-resolver-inbound"
    ]:
```

---

### `azure_dns_zones`

**API version:** `2018-05-01`

Map of Azure DNS zones to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `zone_name` | `string` | yes | — |  |
| `location` | `string` | no | `"global"` |  |
| `zone_type` | `string` | no | `"Public"` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_dns_zones:
  contoso:
    resource_group_name: "rg-dns"
    zone_name: "contoso.com"
```

---

### `azure_email_communication_service_domains`

**API version:** `2026-03-18`

Map of Email Communication Service domains to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `email_service_name` | `string` | yes | — |  |
| `domain_name` | `string` | yes | — |  |
| `location` | `string` | no | `"global"` |  |
| `domain_management` | `string` | no | `"AzureManaged"` |  |
| `user_engagement_tracking` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_email_communication_service_domains:
  azure_managed:
    resource_group_name: "rg-acs"
    email_service_name: "ref:azure_email_communication_services.email.name"
    domain_name: "AzureManagedDomain"
    location: "global"
    domain_management: "AzureManaged"
```

---

### `azure_email_communication_services`

**API version:** `2026-03-18`

Map of Email Communication Services to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `email_service_name` | `string` | yes | — |  |
| `location` | `string` | no | `"global"` |  |
| `data_location` | `string` | no | `"Europe"` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_email_communication_services:
  email:
    resource_group_name: "rg-acs"
    email_service_name: "acs-email-svc"
    location: "global"
    data_location: "Europe"
```

---

### `azure_express_route_circuit_peerings`

**API version:** `2025-05-01`

Map of ExpressRoute circuit peerings to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `circuit_name` | `string` | yes | — |  |
| `peering_name` | `string` | no | `null` |  |
| `peering_type` | `string` | yes | — |  |
| `vlan_id` | `number` | yes | — |  |
| `peer_asn` | `number` | no | `null` |  |
| `primary_peer_address_prefix` | `string` | no | `null` |  |
| `secondary_peer_address_prefix` | `string` | no | `null` |  |
| `shared_key` | `string` | no | `null` |  |
| `state` | `string` | no | `null` |  |
| `azure_asn` | `number` | no | `null` |  |
| `primary_azure_port` | `string` | no | `null` |  |
| `secondary_azure_port` | `string` | no | `null` |  |
| `gateway_manager_etag` | `string` | no | `null` |  |
| `route_filter_id` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_express_route_circuit_peerings:
  private:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    circuit_name: "erc-israelcentral"
    peering_name: "AzurePrivatePeering"
    peering_type: "AzurePrivatePeering"
    vlan_id: 100
    peer_asn: 65515
    primary_peer_address_prefix: "10.0.0.0/30"
    secondary_peer_address_prefix: "10.0.0.4/30"
```

---

### `azure_express_route_circuits`

**API version:** `2025-05-01`

Map of ExpressRoute circuits to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `circuit_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `sku_tier` | `string` | yes | — |  |
| `sku_family` | `string` | yes | — |  |
| `bandwidth_in_gbps` | `number` | no | `null` |  |
| `bandwidth_in_mbps` | `number` | no | `null` |  |
| `express_route_port_id` | `string` | no | `null` |  |
| `service_provider_name` | `string` | no | `null` |  |
| `peering_location` | `string` | no | `null` |  |
| `allow_classic_operations` | `bool` | no | `null` |  |
| `global_reach_enabled` | `bool` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_express_route_ports`

**API version:** `2025-05-01`

Map of ExpressRoute Ports to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `port_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `peering_location` | `string` | yes | — |  |
| `bandwidth_in_gbps` | `number` | yes | — |  |
| `encapsulation` | `string` | yes | — |  |
| `billing_type` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_express_route_ports:
  port1:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    location: "israelcentral"
    peering_location: "Tel Aviv"
    bandwidth_in_gbps: 100
    encapsulation: "Dot1Q"
```

---

### `azure_federated_identity_credentials`

**API version:** `2024-11-30`

Map of federated identity credentials to create for workload identity federation.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `identity_name` | `string` | yes | — |  |
| `federated_credential_name` | `string` | yes | — |  |
| `issuer` | `string` | yes | — |  |
| `subject` | `string` | yes | — |  |
| `audiences` | `list(string)` | no | `["api://AzureADTokenExchange"]` |  |
| `_tenant` | `string` | no | `null` |  |

---

### `azure_firewall_policies`

**API version:** `2025-05-01`

Map of Firewall Policies to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `firewall_policy_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` |  |
| `sku_tier` | `string` | no | `"Standard"` |  |
| `base_policy_id` | `string` | no | `null` |  |
| `threat_intel_mode` | `string` | no | `null` |  |
| `dns_servers` | `list(string)` | no | `null` |  |
| `dns_proxy_enabled` | `bool` | no | `null` |  |
| `explicit_proxy` | `object` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_firewall_policies:
  hub:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    location: "westeurope"
    sku_tier: "Standard"
    threat_intel_mode: "Alert"
```

---

### `azure_firewalls`

**API version:** `2025-05-01`

Map of Azure Firewalls to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `firewall_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` |  |
| `sku_name` | `string` | yes | — |  |
| `sku_tier` | `string` | yes | — |  |
| `virtual_hub_id` | `string` | no | `null` |  |
| `firewall_policy_id` | `string` | no | `null` |  |
| `threat_intel_mode` | `string` | no | `null` |  |
| `public_ip_count` | `number` | no | `null` |  |
| `zones` | `list(string)` | no | `null` |  |
| `ip_configurations` | `list(object)` | no | `null` |  |
| `additional_properties` | `map(string)` | no | `{}` |  |
| `application_rule_collections` | `list(any)` | no | `[]` |  |
| `nat_rule_collections` | `list(any)` | no | `[]` |  |
| `network_rule_collections` | `list(any)` | no | `[]` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_firewalls:
  hub:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    location: "westeurope"
    sku_name: "AZFW_Hub"
    sku_tier: "Standard"
    virtual_hub_id: "/subscriptions/.../providers/Microsoft.Network/virtualHubs/myHub"
    firewall_policy_id: "/subscriptions/.../providers/Microsoft.Network/firewallPolicies/myPolicy"
    public_ip_count: 1
```

---

### `azure_foundry_accounts`

**API version:** `2025-10-01-preview`

Map of Azure AI Foundry accounts to create. Each map key is the for_each identifier.

Azure AI Foundry v2 uses Microsoft.CognitiveServices/accounts with kind=AIFoundry.
This is the NEW Foundry experience at ai.azure.com — not the old Azure AI Studio.

Security defaults (SOC2-ready):
  - public_network_access = "Disabled"
  - disable_local_auth    = true
  - network_acls_default_action = "Deny"

Example (minimum):
  azure_foundry_accounts = {
    main = {
      resource_group_name = "rg-foundry"
      account_name        = "my-foundry"
      location            = "francecentral"
      sku_name            = "S0"
    }
  }

Example (with system identity and project management):
  azure_foundry_accounts = {
    main = {
      resource_group_name      = "rg-foundry"
      account_name             = "my-foundry"
      location                 = "francecentral"
      sku_name                 = "S0"
      identity_type            = "SystemAssigned"
      allow_project_management = true
      public_network_access    = "Enabled"
      disable_local_auth       = true
    }
  }

Example (with customer-managed key):
  azure_foundry_accounts = {
    main = {
      resource_group_name           = "rg-foundry"
      account_name                  = "my-foundry"
      location                      = "francecentral"
      sku_name                      = "S0"
      identity_type                 = "UserAssigned"
      identity_user_assigned_identity_ids = ["ref:azure_user_assigned_identities.foundry.id"]
      encryption_key_source         = "Microsoft.KeyVault"
      encryption_key_vault_uri      = "ref:azure_key_vaults.foundry.vault_uri"
      encryption_key_name           = "ref:azure_key_vault_keys.foundry.name"
      encryption_identity_client_id = "ref:azure_user_assigned_identities.foundry.client_id"
    }
  }

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | `null` |  |
| `resource_group_name` | `string` | yes | — |  |
| `account_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` |  |
| `kind` | `string` | no | `"AIFoundry"` |  |
| `sku_name` | `string` | yes | — |  |
| `sku_capacity` | `number` | no | `null` |  |
| `sku_tier` | `string` | no | `null` |  |
| `identity_type` | `string` | no | `null` |  |
| `identity_user_assigned_identity_ids` | `list(string)` | no | `null` |  |
| `public_network_access` | `string` | no | `"Disabled"` |  |
| `network_acls_default_action` | `string` | no | `"Deny"` |  |
| `network_acls_bypass` | `string` | no | `null` |  |
| `network_acls_ip_rules` | `list(string)` | no | `null` |  |
| `network_acls_virtual_network_rules` | `list(object)` | no | `null` |  |
| `network_injections` | `list(object)` | no | `null` |  |
| `restrict_outbound_network_access` | `bool` | no | `null` |  |
| `allowed_fqdn_list` | `list(string)` | no | `null` |  |
| `encryption_key_source` | `string` | no | `null` |  |
| `encryption_key_vault_uri` | `string` | no | `null` |  |
| `encryption_key_name` | `string` | no | `null` |  |
| `encryption_key_version` | `string` | no | `null` |  |
| `encryption_identity_client_id` | `string` | no | `null` |  |
| `disable_local_auth` | `bool` | no | `true` |  |
| `stored_completions_disabled` | `bool` | no | `null` |  |
| `dynamic_throttling_enabled` | `bool` | no | `null` |  |
| `allow_project_management` | `bool` | no | `null` |  |
| `associated_projects` | `list(string)` | no | `null` |  |
| `default_project` | `string` | no | `null` |  |
| `custom_sub_domain_name` | `string` | no | `null` |  |
| `user_owned_storage` | `list(object)` | no | `null` |  |
| `rai_monitor_config_storage_resource_id` | `string` | no | `null` |  |
| `rai_monitor_config_identity_client_id` | `string` | no | `null` |  |
| `aml_workspace_resource_id` | `string` | no | `null` |  |
| `aml_workspace_identity_client_id` | `string` | no | `null` |  |
| `restore` | `bool` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_foundry_deployments`

**API version:** `2025-09-01`

Map of Azure AI Foundry model deployments to create. Each map key is the for_each
identifier. Deployments must reference an existing Foundry account.

A plan-time precondition validates that model_name is available in the target
location before applying. If the model is not available, terraform plan fails
with a CLI command to list available models.

Example (GPT-4o GlobalStandard):
  azure_foundry_deployments = {
    gpt4o = {
      resource_group_name    = "rg-foundry"
      account_name           = "my-foundry"
      location               = "francecentral"
      deployment_name        = "gpt-4o"
      model_format           = "OpenAI"
      model_name             = "gpt-4o"
      model_version          = "2024-08-06"
      sku_name               = "GlobalStandard"
      sku_capacity           = 100
      version_upgrade_option = "OnceNewDefaultVersionAvailable"
    }
  }

Example (embeddings + spillover):
  azure_foundry_deployments = {
    embeddings = {
      resource_group_name       = "rg-foundry"
      account_name              = "my-foundry"
      location                  = "francecentral"
      deployment_name           = "text-embedding-3-large"
      model_format              = "OpenAI"
      model_name                = "text-embedding-3-large"
      sku_name                  = "Standard"
      sku_capacity              = 50
      version_upgrade_option    = "NoAutoUpgrade"
      spillover_deployment_name = "text-embedding-3-large-fallback"
    }
  }

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | `null` |  |
| `resource_group_name` | `string` | yes | — |  |
| `account_name` | `string` | yes | — |  |
| `location` | `string` | yes | — |  |
| `deployment_name` | `string` | yes | — |  |
| `model_format` | `string` | yes | — |  |
| `model_name` | `string` | yes | — |  |
| `model_version` | `string` | no | `null` |  |
| `model_publisher` | `string` | no | `null` |  |
| `model_source` | `string` | no | `null` |  |
| `model_source_account` | `string` | no | `null` |  |
| `sku_name` | `string` | yes | — |  |
| `sku_capacity` | `number` | no | `null` |  |
| `version_upgrade_option` | `string` | no | `"OnceNewDefaultVersionAvailable"` |  |
| `rai_policy_name` | `string` | no | `null` |  |
| `scale_type` | `string` | no | `null` |  |
| `scale_capacity` | `number` | no | `null` |  |
| `capacity_settings_designated_capacity` | `number` | no | `null` |  |
| `capacity_settings_priority` | `number` | no | `null` |  |
| `parent_deployment_name` | `string` | no | `null` |  |
| `spillover_deployment_name` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_foundry_managed_networks`

**API version:** `2025-10-01-preview`

Map of Azure AI Foundry managed networks to configure. The managed network name
is always 'default'. Each map key acts as the for_each identifier.

IMPORTANT: Requires the AI.ManagedVnetPreview feature flag and a supported region.
The managed network cannot be deleted independently — it is deleted with the account.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | `null` |  |
| `resource_group_name` | `string` | yes | — |  |
| `account_name` | `string` | yes | — |  |
| `location` | `string` | no | `"francecentral"` |  |
| `isolation_mode` | `string` | no | `"AllowOnlyApprovedOutbound"` |  |
| `managed_network_kind` | `string` | no | `"V2"` |  |
| `firewall_sku` | `string` | no | `"Standard"` |  |
| `outbound_rules` | `map(object)` | no | `null` |  |

#### YAML Example

```yaml
azure_foundry_managed_networks:
  main:
    resource_group_name: "rg-foundry"
    account_name: "my-foundry"
    location: "francecentral"
    isolation_mode: "AllowOnlyApprovedOutbound"
    managed_network_kind: "V2"
    firewall_sku: "Standard"
```

---

### `azure_github_network_settings`

**API version:** `2024-04-02`

Map of GitHub.Network networkSettings resources to create. Links an Azure
subnet to a GitHub organization/enterprise for VNet-injected hosted runners.

Requires:
  - The GitHub.Network resource provider registered on the subscription
  - A subnet with delegation to GitHub.Network/networkSettings
  - The GitHub business (org/enterprise) database ID

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `network_settings_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `subnet_id` | `string` | yes | — |  |
| `business_id` | `string` | yes | — |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_github_network_settings:
  runners:
    resource_group_name: "rg-github-runners"
    subnet_id: "/subscriptions/.../subnets/runner-subnet"
    business_id: "123456789"
```

---

### `azure_ipam_pools`

**API version:** `2025-05-01`

Map of IPAM Pools to create under a Network Manager. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `network_manager_name` | `string` | yes | — |  |
| `pool_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `address_prefixes` | `list(string)` | yes | — |  |
| `description` | `string` | no | `null` |  |
| `display_name` | `string` | no | `null` |  |
| `parent_pool_name` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_ipam_pools:
  root:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    network_manager_name: "nm-main"
    location: "westeurope"
    address_prefixes: ["10.0.0.0/8"]
```

---

### `azure_ipam_static_cidrs`

**API version:** `2025-05-01`

Map of IPAM Static CIDR allocations. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `network_manager_name` | `string` | yes | — |  |
| `pool_name` | `string` | yes | — |  |
| `static_cidr_name` | `string` | no | `null` |  |
| `address_prefixes` | `list(string)` | no | `null` |  |
| `number_of_ip_addresses_to_allocate` | `string` | no | `null` |  |
| `description` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_ipam_static_cidrs:
  hub1:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    network_manager_name: "nm-main"
    pool_name: "pool-hubs"
    address_prefixes: ["10.1.0.0/24"]
    description: "Virtual Hub 1"
```

---

### `azure_key_vault_keys`

**API version:** `2026-02-01`

Map of key vault keys to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `vault_name` | `string` | yes | — |  |
| `key_name` | `string` | yes | — |  |
| `key_type` | `string` | yes | — |  |
| `key_size` | `number` | no | `null` |  |
| `curve_name` | `string` | no | `null` |  |
| `key_ops` | `list(string)` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_key_vault_keys:
  cmk_sa:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-myapp-prod"
    vault_name: "kv-myapp-prod"
    key_name: "cmk-storage"
    key_type: "RSA"
    key_size: 2048
```

---

### `azure_key_vaults`

**API version:** `2026-02-01`

Map of key vaults to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `vault_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` |  |
| `tenant_id` | `string` | yes | — |  |
| `sku_name` | `string` | no | `"standard"` |  |
| `tags` | `map(string)` | no | `null` |  |
| `enable_rbac_authorization` | `bool` | no | `true` |  |
| `enable_purge_protection` | `bool` | no | `null` |  |
| `enable_soft_delete` | `bool` | no | `true` |  |
| `soft_delete_retention_in_days` | `number` | no | `90` |  |
| `enabled_for_deployment` | `bool` | no | `null` |  |
| `enabled_for_disk_encryption` | `bool` | no | `null` |  |
| `enabled_for_template_deployment` | `bool` | no | `null` |  |
| `public_network_access` | `string` | no | `null` |  |
| `create_mode` | `string` | no | `null` |  |
| `network_acls` | `object` | no | `null` |  |

#### YAML Example

```yaml
azure_key_vaults:
  cmk:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    tenant_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-myapp-prod"
    location: "westeurope"
    enable_rbac_authorization: true
    enable_purge_protection: true
```

---

### `azure_load_balancers`

**API version:** `2025-05-01`

Map of load balancers to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `load_balancer_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `sku_name` | `string` | yes | — |  |
| `sku_tier` | `string` | no | `null` |  |
| `frontend_ip_configurations` | `list(object)` | no | `null` |  |
| `backend_address_pools` | `list(object)` | no | `null` |  |
| `probes` | `list(object)` | no | `null` |  |
| `load_balancing_rules` | `list(object)` | no | `null` |  |
| `inbound_nat_rules` | `list(object)` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_managed_clusters`

**API version:** `2026-01-01`

Map of AKS managed clusters to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `cluster_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `sku_name` | `string` | no | `"Automatic"` |  |
| `sku_tier` | `string` | no | `"Standard"` |  |
| `identity_type` | `string` | no | `"SystemAssigned"` |  |
| `identity_user_assigned_identity_ids` | `list(string)` | no | `null` |  |
| `kubernetes_version` | `string` | no | `null` |  |
| `dns_prefix` | `string` | no | `null` |  |
| `node_resource_group` | `string` | no | `null` |  |
| `network_plugin` | `string` | no | `"azure"` |  |
| `network_plugin_mode` | `string` | no | `"overlay"` |  |
| `network_dataplane` | `string` | no | `"cilium"` |  |
| `network_policy` | `string` | no | `"cilium"` |  |
| `service_cidr` | `string` | no | `null` |  |
| `dns_service_ip` | `string` | no | `null` |  |
| `pod_cidr` | `string` | no | `null` |  |
| `outbound_type` | `string` | no | `null` |  |
| `load_balancer_sku` | `string` | no | `null` |  |
| `enable_private_cluster` | `bool` | no | `false` |  |
| `private_dns_zone` | `string` | no | `null` |  |
| `enable_private_cluster_public_fqdn` | `bool` | no | `null` |  |
| `disable_run_command` | `bool` | no | `null` |  |
| `authorized_ip_ranges` | `list(string)` | no | `null` |  |
| `enable_vnet_integration` | `bool` | no | `null` |  |
| `api_server_subnet_id` | `string` | no | `null` |  |
| `aad_managed` | `bool` | no | `true` |  |
| `aad_enable_azure_rbac` | `bool` | no | `true` |  |
| `aad_admin_group_object_ids` | `list(string)` | no | `null` |  |
| `aad_tenant_id` | `string` | no | `null` |  |
| `enable_workload_identity` | `bool` | no | `true` |  |
| `enable_defender` | `bool` | no | `false` |  |
| `defender_log_analytics_workspace_id` | `string` | no | `null` |  |
| `enable_image_cleaner` | `bool` | no | `null` |  |
| `image_cleaner_interval_hours` | `number` | no | `null` |  |
| `enable_oidc_issuer` | `bool` | no | `true` |  |
| `upgrade_channel` | `string` | no | `"stable"` |  |
| `node_os_upgrade_channel` | `string` | no | `null` |  |
| `node_provisioning_mode` | `string` | no | `null` |  |
| `agent_pool_profiles` | `list(object)` | no | `null` |  |
| `disable_local_accounts` | `bool` | no | `true` |  |
| `enable_rbac` | `bool` | no | `true` |  |
| `public_network_access` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_management_locks`

**API version:** `2020-05-01`

Map of management locks to create at the resource group level.
Use CanNotDelete locks on critical infrastructure (e.g. state storage)
to prevent accidental deletion.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | `null` |  |
| `resource_group_name` | `string` | yes | — |  |
| `lock_name` | `string` | yes | — |  |
| `lock_level` | `string` | no | `"CanNotDelete"` |  |
| `notes` | `string` | no | `null` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_management_locks:
  protect_state:
    resource_group_name: "rg-terraform-state"
    lock_name: "protect-terraform-state"
    lock_level: "CanNotDelete"
    notes: "Protects Terraform state storage from accidental deletion."
```

---

### `azure_network_interfaces`

**API version:** `2025-05-01`

Map of network interfaces to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `network_interface_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `ip_configurations` | `list(object)` | yes | — |  |
| `enable_accelerated_networking` | `bool` | no | `null` |  |
| `enable_ip_forwarding` | `bool` | no | `null` |  |
| `dns_servers` | `list(string)` | no | `null` |  |
| `network_security_group_id` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_network_managers`

**API version:** `2025-05-01`

Map of Azure Network Managers to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `network_manager_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `description` | `string` | no | `null` |  |
| `scope_subscriptions` | `list(string)` | no | `null` |  |
| `scope_management_groups` | `list(string)` | no | `null` |  |
| `scope_accesses` | `list(string)` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_network_managers:
  main:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    location: "westeurope"
    scope_subscriptions: ["/subscriptions/00000000-0000-0000-0000-000000000000"]
```

---

### `azure_postgresql_flexible_server_administrators`

**API version:** `2025-08-01`

Map of PostgreSQL Flexible Server Entra administrators to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `server_name` | `string` | yes | — |  |
| `object_id` | `string` | yes | — |  |
| `principal_type` | `string` | no | `"ServicePrincipal"` |  |
| `principal_name` | `string` | yes | — |  |
| `tenant_id` | `string` | yes | — |  |

---

### `azure_postgresql_flexible_servers`

**API version:** `2025-08-01`

Map of PostgreSQL Flexible Servers to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `server_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `sku_name` | `string` | no | `"Standard_D2ds_v5"` |  |
| `sku_tier` | `string` | no | `"GeneralPurpose"` |  |
| `server_version` | `string` | no | `"16"` |  |
| `administrator_login` | `string` | no | `null` |  |
| `administrator_login_password` | `string` | no | `null` |  |
| `active_directory_auth` | `string` | no | `null` |  |
| `password_auth` | `string` | no | `null` |  |
| `auth_tenant_id` | `string` | no | `null` |  |
| `storage_size_gb` | `number` | no | `32` |  |
| `storage_auto_grow` | `string` | no | `null` |  |
| `storage_tier` | `string` | no | `null` |  |
| `backup_retention_days` | `number` | no | `null` |  |
| `geo_redundant_backup` | `string` | no | `null` |  |
| `ha_mode` | `string` | no | `null` |  |
| `ha_standby_availability_zone` | `string` | no | `null` |  |
| `delegated_subnet_id` | `string` | no | `null` |  |
| `private_dns_zone_id` | `string` | no | `null` |  |
| `public_network_access` | `string` | no | `null` |  |
| `availability_zone` | `string` | no | `null` |  |
| `maintenance_window` | `object` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_private_dns_zones`

**API version:** `2024-06-01`

Map of Private DNS zones to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `zone_name` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |
| `virtual_network_links` | `list(object)` | no | `[]` |  |

---

### `azure_private_endpoints`

**API version:** `2025-05-01`

Map of private endpoints to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `private_endpoint_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `subnet_id` | `string` | yes | — |  |
| `custom_network_interface_name` | `string` | no | `null` |  |
| `private_link_service_connections` | `list(object)` | no | `null` |  |
| `manual_private_link_service_connections` | `list(object)` | no | `null` |  |
| `ip_configurations` | `list(object)` | no | `null` |  |
| `private_dns_zone_group` | `object` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_public_ip_addresses`

**API version:** `2025-05-01`

Map of public IP addresses to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `public_ip_address_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `sku_name` | `string` | yes | — |  |
| `sku_tier` | `string` | no | `null` |  |
| `allocation_method` | `string` | yes | — |  |
| `ip_version` | `string` | no | `null` |  |
| `idle_timeout_in_minutes` | `number` | no | `null` |  |
| `zones` | `list(string)` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_redis_enterprise_clusters`

**API version:** `2025-07-01`

Map of Redis Enterprise clusters to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `cluster_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `sku_name` | `string` | yes | — |  |
| `sku_capacity` | `number` | no | `null` |  |
| `zones` | `list(string)` | no | `null` |  |
| `minimum_tls_version` | `string` | no | `"1.2"` |  |
| `high_availability` | `string` | no | `null` |  |
| `public_network_access` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_redis_enterprise_databases`

**API version:** `2025-07-01`

Map of Redis Enterprise databases to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `cluster_name` | `string` | yes | — |  |
| `database_name` | `string` | no | `"default"` |  |
| `client_protocol` | `string` | no | `"Encrypted"` |  |
| `port` | `number` | no | `10000` |  |
| `clustering_policy` | `string` | no | `"OSSCluster"` |  |
| `eviction_policy` | `string` | no | `"VolatileLRU"` |  |
| `access_keys_authentication` | `string` | no | `null` |  |
| `modules` | `list(object)` | no | `null` |  |
| `persistence` | `object` | no | `null` |  |

---

### `azure_resource_groups`

**API version:** `2025-04-01`

Map of resource groups to create or manage. Each map key acts as the for_each
identifier and must be unique within this configuration.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` | null → resolved from var.default_location |
| `managed_by` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_resource_groups:
  networking:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    tags:
      environment: "production"
      team: "networking"
  compute:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-compute-prod"  # explicit override
    location: "eastus"
    managed_by: "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/management-rg"
```

---

### `azure_resource_provider_features`

**API version:** `2021-07-01`

Map of resource provider features to register on a subscription. Each map key
acts as the for_each identifier.

Use this to selectively enable specific provider features. When a resource
provider is registered without specific features, all features are enabled
by default.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | `null` |  |
| `provider_namespace` | `string` | yes | — |  |
| `feature_name` | `string` | yes | — |  |
| `state` | `string` | no | `"Registered"` |  |
| `metadata` | `map(string)` | no | `null` |  |
| `description` | `string` | no | `null` |  |
| `should_feature_display_in_portal` | `bool` | no | `null` |  |

#### YAML Example

```yaml
azure_resource_provider_features:
  encryption_at_host:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    provider_namespace: "Microsoft.Compute"
    feature_name: "EncryptionAtHost"
```

---

### `azure_resource_provider_registrations`

**API version:** `2025-04-01`

Map of resource providers to register on a subscription. Each map key acts as
the for_each identifier.

When a provider is registered without specifying individual features, all
features are enabled by default (standard Azure behavior). Use the
resource_provider_features variable to selectively register specific features.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | `null` |  |
| `resource_provider_namespace` | `string` | yes | — |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_resource_provider_registrations:
  compute:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_provider_namespace: "Microsoft.Compute"
```

---

### `azure_role_assignments`

**API version:** `2022-04-01`

Map of role assignments to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `scope` | `string` | yes | — |  |
| `role_definition_id` | `string` | yes | — |  |
| `principal_id` | `string` | yes | — |  |
| `principal_type` | `string` | no | `"ServicePrincipal"` |  |
| `description` | `string` | no | `null` |  |
| `condition` | `string` | no | `null` |  |
| `condition_version` | `string` | no | `null` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_role_assignments:
  cmk_sa_crypto_user:
    scope: "/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/my-kv"
    role_definition_id: "/subscriptions/.../providers/Microsoft.Authorization/roleDefinitions/12338..."
    principal_id: "00000000-0000-0000-0000-000000000000"
    principal_type: "ServicePrincipal"
```

---

### `azure_role_assignments_post`

**API version:** `2022-04-01`

Role assignments that depend on L3 resources (e.g. AKS clusters).
Same schema as azure_role_assignments but resolved at _ctx_l3.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `scope` | `string` | yes | — |  |
| `role_definition_id` | `string` | yes | — |  |
| `principal_id` | `string` | yes | — |  |
| `principal_type` | `string` | no | `"ServicePrincipal"` |  |
| `description` | `string` | no | `null` |  |
| `condition` | `string` | no | `null` |  |
| `condition_version` | `string` | no | `null` |  |

---

### `azure_route_tables`

**API version:** `2025-05-01`

Map of route tables to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `route_table_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `disable_bgp_route_propagation` | `bool` | no | `null` |  |
| `routes` | `list(object)` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_routing_intents`

**API version:** `2025-05-01`

Map of Routing Intents to create. Each map key acts as the for_each identifier.
Routing Intent is a singleton per Virtual Hub.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `virtual_hub_name` | `string` | yes | — |  |
| `routing_intent_name` | `string` | no | `"RoutingIntent"` |  |
| `firewall_id` | `string` | yes | — |  |
| `internet_traffic` | `bool` | no | `true` |  |
| `private_traffic` | `bool` | no | `true` |  |

#### YAML Example

```yaml
azure_routing_intents:
  hub:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    virtual_hub_name: "vhub-westeurope"
    firewall_id: "/subscriptions/.../providers/Microsoft.Network/azureFirewalls/myFirewall"
    internet_traffic: true
    private_traffic: true
```

---

### `azure_storage_account_containers`

**API version:** `2025-08-01`

Map of blob containers to create inside storage accounts.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | no | `null` |  |
| `resource_group_name` | `string` | yes | — |  |
| `account_name` | `string` | yes | — |  |
| `container_name` | `string` | yes | — |  |
| `public_access` | `string` | no | `"None"` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_storage_account_containers:
  tfstate:
    resource_group_name: "rg-terraform-state"
    account_name: "stdplstate001"
    container_name: "tfstate"
```

---

### `azure_storage_accounts`

**API version:** `2025-08-01`

Map of storage accounts to create or manage. Each map key acts as the for_each
identifier and must be unique within this configuration.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `account_name` | `string` | yes | — |  |
| `sku_name` | `string` | yes | — |  |
| `kind` | `string` | yes | — |  |
| `location` | `string` | no | `null` | null → resolved from var.default_location |
| `tags` | `map(string)` | no | `null` |  |
| `zones` | `list(string)` | no | `null` |  |
| `identity_type` | `string` | no | `null` |  |
| `identity_user_assigned_identity_ids` | `list(string)` | no | `null` |  |
| `access_tier` | `string` | no | `null` |  |
| `https_traffic_only_enabled` | `bool` | no | `true` |  |
| `minimum_tls_version` | `string` | no | `"TLS1_2"` |  |
| `allow_blob_public_access` | `bool` | no | `false` |  |
| `allow_shared_key_access` | `bool` | no | `null` |  |
| `is_hns_enabled` | `bool` | no | `null` |  |
| `public_network_access` | `string` | no | `null` |  |
| `default_to_oauth_authentication` | `bool` | no | `null` |  |
| `allow_cross_tenant_replication` | `bool` | no | `null` |  |
| `network_acls` | `object` | no | `null` |  |
| `encryption_key_source` | `string` | no | `null` |  |
| `encryption_key_vault_uri` | `string` | no | `null` |  |
| `encryption_key_name` | `string` | no | `null` |  |
| `encryption_key_version` | `string` | no | `null` |  |
| `encryption_identity` | `string` | no | `null` |  |
| `encryption_require_infrastructure_encryption` | `bool` | no | `null` |  |

#### YAML Example

```yaml
azure_storage_accounts:
  app_data:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-myapp-prod"
    account_name: "myappdata"  # globally unique, 3-24 lowercase alphanumeric
    sku_name: "Standard_LRS"
    kind: "StorageV2"
    tags:
      environment: "production"
      team: "platform"
  datalake:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-data-prod"
    account_name: "mydatalakeprod"  # explicit override
    sku_name: "Standard_ZRS"
    kind: "StorageV2"
    location: "northeurope"
    is_hns_enabled: true
```

---

### `azure_subscriptions`

**API version:** `2021-10-01`

Map of subscriptions to create via subscription aliases. Each map key acts as
the for_each identifier. When alias_name is omitted, the map key is used.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `alias_name` | `string` | no | `null` | null → uses the map key |
| `display_name` | `string` | yes | — |  |
| `billing_scope` | `string` | yes | — |  |
| `workload` | `string` | yes | — |  |
| `subscription_id` | `string` | no | `null` |  |
| `reseller_id` | `string` | no | `null` |  |
| `management_group_id` | `string` | no | `null` |  |
| `subscription_tenant_id` | `string` | no | `null` |  |
| `subscription_owner_id` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_subscriptions:
  dev:
    display_name: "Development Subscription"
    billing_scope: "/billingAccounts/.../enrollmentAccounts/..."
    workload: "DevTest"
```

---

### `azure_user_assigned_identities`

**API version:** `2024-11-30`

Map of user-assigned managed identities to create. Each map key acts as the
for_each identifier and must be unique within this configuration.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `identity_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |
| `_tenant` | `string` | no | `null` |  |

#### YAML Example

```yaml
azure_user_assigned_identities:
  cmk_sa:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-myapp-prod"
    location: "westeurope"
```

---

### `azure_virtual_hub_connections`

**API version:** `2025-05-01`

Map of Virtual Hub VNet Connections to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `virtual_hub_name` | `string` | yes | — |  |
| `connection_name` | `string` | no | `null` |  |
| `remote_virtual_network_id` | `string` | yes | — |  |
| `enable_internet_security` | `bool` | no | `null` |  |
| `allow_hub_to_remote_vnet_transit` | `bool` | no | `null` |  |
| `allow_remote_vnet_to_use_hub_vnet_gateways` | `bool` | no | `null` |  |

#### YAML Example

```yaml
azure_virtual_hub_connections:
  hub3-vnet1:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    virtual_hub_name: "vhub-israelcentral-01"
    remote_virtual_network_id: "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/myVnet"
    enable_internet_security: true
```

---

### `azure_virtual_hubs`

**API version:** `2025-05-01`

Map of Virtual Hubs to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `virtual_hub_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` |  |
| `virtual_wan_id` | `string` | yes | — |  |
| `address_prefix` | `string` | yes | — |  |
| `sku` | `string` | no | `"Standard"` |  |
| `allow_branch_to_branch_traffic` | `bool` | no | `null` |  |
| `hub_routing_preference` | `string` | no | `null` |  |
| `virtual_router_auto_scale_min_capacity` | `number` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_virtual_hubs:
  hub:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    location: "westeurope"
    virtual_wan_id: "/subscriptions/.../providers/Microsoft.Network/virtualWans/myWan"
    address_prefix: "10.0.0.0/24"
    sku: "Standard"
```

---

### `azure_virtual_network_gateway_connections`

**API version:** `2025-05-01`

Map of virtual network gateway connections to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `connection_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `connection_type` | `string` | yes | — |  |
| `virtual_network_gateway1_id` | `string` | yes | — |  |
| `virtual_network_gateway2_id` | `string` | no | `null` |  |
| `peer_id` | `string` | no | `null` |  |
| `routing_weight` | `number` | no | `null` |  |
| `enable_bgp` | `bool` | no | `null` |  |
| `express_route_gateway_bypass` | `bool` | no | `null` |  |
| `enable_private_link_fast_path` | `bool` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_virtual_network_gateways`

**API version:** `2025-05-01`

Map of virtual network gateways to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `gateway_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `gateway_type` | `string` | yes | — |  |
| `sku_name` | `string` | yes | — |  |
| `sku_tier` | `string` | yes | — |  |
| `vpn_type` | `string` | no | `null` |  |
| `vpn_gateway_generation` | `string` | no | `null` |  |
| `enable_bgp` | `bool` | no | `null` |  |
| `active_active` | `bool` | no | `null` |  |
| `enable_private_ip_address` | `bool` | no | `null` |  |
| `admin_state` | `string` | no | `null` |  |
| `ip_configurations` | `list(object)` | no | `null` |  |
| `vpn_client_configuration` | `object` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_virtual_network_peerings`

**API version:** `2025-05-01`

Map of VNet peerings to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `virtual_network_name` | `string` | yes | — |  |
| `peering_name` | `string` | no | `null` |  |
| `remote_virtual_network_id` | `string` | yes | — |  |
| `allow_virtual_network_access` | `bool` | no | `true` |  |
| `allow_forwarded_traffic` | `bool` | no | `false` |  |
| `allow_gateway_transit` | `bool` | no | `false` |  |
| `use_remote_gateways` | `bool` | no | `false` |  |

---

### `azure_virtual_networks`

**API version:** `2025-05-01`

Map of virtual networks to create.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `virtual_network_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `address_space` | `list(string)` | yes | — |  |
| `dns_servers` | `list(string)` | no | `null` |  |
| `enable_ddos_protection` | `bool` | no | `null` |  |
| `ddos_protection_plan_id` | `string` | no | `null` |  |
| `subnets` | `list(object)` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

---

### `azure_virtual_wans`

**API version:** `2025-05-01`

Map of Virtual WANs to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `virtual_wan_name` | `string` | yes | — |  |
| `location` | `string` | no | `null` |  |
| `type` | `string` | no | `"Standard"` |  |
| `disable_vpn_encryption` | `bool` | no | `null` |  |
| `allow_branch_to_branch_traffic` | `bool` | no | `null` |  |
| `allow_vnet_to_vnet_traffic` | `bool` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_virtual_wans:
  hub:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    location: "westeurope"
    type: "Standard"
```

---

### `azure_vpn_gateways`

**API version:** `2025-05-01`

Map of VPN Gateways (vWAN S2S) to create. Each map key acts as the for_each identifier.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `subscription_id` | `string` | yes | — |  |
| `resource_group_name` | `string` | yes | — |  |
| `gateway_name` | `string` | no | `null` |  |
| `location` | `string` | no | `null` |  |
| `virtual_hub_id` | `string` | yes | — |  |
| `vpn_gateway_scale_unit` | `number` | no | `null` |  |
| `enable_bgp_route_translation_for_nat` | `bool` | no | `null` |  |
| `is_routing_preference_internet` | `bool` | no | `null` |  |
| `tags` | `map(string)` | no | `null` |  |

#### YAML Example

```yaml
azure_vpn_gateways:
  hub1:
    subscription_id: "00000000-0000-0000-0000-000000000000"
    resource_group_name: "rg-networking"
    location: "westus"
    virtual_hub_id: "/subscriptions/.../providers/Microsoft.Network/virtualHubs/myHub"
    vpn_gateway_scale_unit: 40
```

---
