# Azure AI Foundry Managed Network Module

Manages the managed virtual network for an Azure AI Foundry account
(`Microsoft.CognitiveServices/accounts/managedNetworks/default`).

> **Hero module:** Full schema coverage with typed outbound rule validation, irreversibility warnings, and complete documentation.

## Overview

The managed virtual network enables secure egress control for AI Foundry Agent compute. When enabled, all Agent outbound traffic is routed through the managed network and filtered by the configured isolation mode.

Key facts:
- Each Foundry account has exactly **one** managed network (`/default`)
- The managed network must be co-located with its parent account
- **Enabling is irreversible** — isolation mode cannot be changed or disabled once set
- FQDN rules trigger automatic creation of a managed Azure Firewall (extra cost)
- Requires the `AI.ManagedVnetPreview` preview feature (approval takes several hours)

> **Deletion behaviour:** `managedNetworks/default` does not support independent DELETE (returns 405). It is removed automatically when the parent Foundry account is deleted. This module uses `rest_operation` — Terraform will not attempt DELETE on `terraform destroy`.

## API Version

`2025-04-01-preview`

## Preview Feature Registration

Register the feature before deploying. Approval takes several hours:

```bash
az feature register --namespace Microsoft.CognitiveServices --name AI.ManagedVnetPreview

az feature show --namespace Microsoft.CognitiveServices --name AI.ManagedVnetPreview \
  --query "properties.state" -o tsv
# Wait until output is: Registered
```

Track this in Terraform via the `azure_resource_provider_features` root map:

```yaml
azure_resource_provider_features:
  foundry_managed_vnet:
    provider_namespace: Microsoft.CognitiveServices
    feature_name: AI.ManagedVnetPreview
    state: Registered
```

## Isolation Mode Reference

| Mode | Outbound access | Notes |
|---|---|---|
| `AllowOnlyApprovedOutbound` | Only approved destinations (service tags, PEs, FQDNs) | **Default** — recommended for production |
| `AllowInternetOutbound` | All internet traffic | Weaker data-exfiltration protection |
| `Disabled` | No managed network isolation | Use with a custom VNet |

> **WARNING:** Once set to `AllowInternetOutbound` or `AllowOnlyApprovedOutbound`, this setting **cannot be changed back** to `Disabled`. Changing from `AllowInternetOutbound` to `AllowOnlyApprovedOutbound` is also not supported.

## Managed Network Kind

| Kind | Description |
|---|---|
| `V2` | Granular access controls — recommended for new deployments (default) |
| `V1` | Legacy access controls |

> **WARNING:** V2 cannot be reverted to V1 after initial deployment.

## Firewall SKU

| SKU | Features | Notes |
|---|---|---|
| `Standard` | Threat intelligence, full rule support | Default — recommended |
| `Basic` | Basic filtering, lower cost | Sufficient for dev/test |

> **WARNING:** Firewall SKU cannot be changed after initial deployment.

## Outbound Rule Types

### FQDN Rule

Allows outbound traffic to a specific fully qualified domain name. Requires:
- `isolation_mode = "AllowOnlyApprovedOutbound"`
- A managed Azure Firewall (Standard or Basic)
- Only ports 80 and 443 are supported

```yaml
outbound_rules:
  my_fqdn:
    type: FQDN
    fqdn_destination: "*.example.com"
```

### PrivateEndpoint Rule

Creates a managed private endpoint from the Foundry managed network to an Azure resource. The Foundry managed identity must have the `Azure AI Enterprise Network Connection Approver` role on the target resource to auto-approve the connection.

```yaml
outbound_rules:
  my_storage_pe:
    type: PrivateEndpoint
    private_endpoint_service_resource_id: /subscriptions/.../storageAccounts/mystorage
    private_endpoint_subresource_target: blob
    private_endpoint_fqdns:
      - mystorage.blob.core.windows.net
```

### ServiceTag Rule

Allows outbound to an Azure service tag. Use this for connectivity to Azure services like Entra ID, Storage, Key Vault, etc.

```yaml
outbound_rules:
  entra_id:
    type: ServiceTag
    service_tag: AzureActiveDirectory
    service_tag_action: Allow
    service_tag_protocol: TCP
    service_tag_port_ranges: "443"
```

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `subscription_id` | string | yes | — | Azure subscription ID |
| `resource_group_name` | string | yes | — | Resource group of the parent account |
| `account_name` | string | yes | — | Parent Foundry account name |
| `location` | string | yes | `francecentral` | Azure region (must be in the 20 supported regions) |
| `isolation_mode` | string | no | `AllowOnlyApprovedOutbound` | Isolation mode (see table above — **irreversible**) |
| `managed_network_kind` | string | no | `V2` | `V1` or `V2` (**V2 cannot revert to V1**) |
| `firewall_sku` | string | no | `Standard` | `Basic` or `Standard` (**irreversible**) |
| `outbound_rules` | map(object) | no | null | Named outbound rules (FQDN, PrivateEndpoint, ServiceTag) |

### Supported Regions

Managed virtual network (preview) is only supported in:
`eastus`, `eastus2`, `japaneast`, `francecentral`, `uaenorth`, `brazilsouth`, `spaincentral`, `germanywestcentral`, `italynorth`, `southcentralus`, `westcentralus`, `australiaeast`, `swedencentral`, `canadaeast`, `southafricanorth`, `westeurope`, `westus`, `westus3`, `southindia`, `uksouth`.

### Outbound Rule Object Schema

| Field | Type | Required for | Description |
|---|---|---|---|
| `type` | string | all | `FQDN`, `PrivateEndpoint`, or `ServiceTag` |
| `category` | string | — | `UserDefined` (default), `Dependency`, `Recommended`, `Required` |
| `fqdn_destination` | string | FQDN | Destination domain (e.g. `*.example.com`) |
| `private_endpoint_service_resource_id` | string | PrivateEndpoint | Target ARM resource ID |
| `private_endpoint_subresource_target` | string | PrivateEndpoint | Sub-resource type (`blob`, `queue`, `vault`, etc.) |
| `private_endpoint_fqdns` | list(string) | — | FQDNs for the private endpoint |
| `service_tag` | string | ServiceTag | Azure service tag (e.g. `AzureActiveDirectory`) |
| `service_tag_action` | string | ServiceTag | `Allow` (default) |
| `service_tag_protocol` | string | ServiceTag | `TCP`, `UDP`, `ICMP`, or `*` |
| `service_tag_port_ranges` | string | ServiceTag | Port or range (e.g. `443` or `1024-65535`) |
| `service_tag_address_prefixes` | list(string) | — | Override address prefixes |

### Cross-Field Validation Rules

The module validates that each rule type includes its required fields:
- `FQDN` rules: `fqdn_destination` must be set
- `PrivateEndpoint` rules: `private_endpoint_service_resource_id` must be set
- `ServiceTag` rules: `service_tag` must be set
- `category` when set must be `Dependency`, `Recommended`, `Required`, or `UserDefined`

## Outputs

| Name | Plan-time | Description |
|---|---|---|
| `id` | yes | Full ARM resource path |
| `api_version` | yes | ARM API version in use |
| `account_name` | yes | Parent account name (echoes input) |
| `resource_group_name` | yes | Resource group (echoes input) |
| `isolation_mode` | yes | Isolation mode (echoes input) |
| `managed_network_kind` | yes | Network kind V1/V2 (echoes input) |
| `provisioning_state` | after apply | Provisioning state (Succeeded, etc.) |
| `network_isolation_mode` | after apply | Isolation mode as confirmed by Azure |
| `network_kind` | after apply | Network kind as confirmed by Azure |
| `firewall_sku` | after apply | Firewall SKU as confirmed by Azure |
| `network_status` | after apply | Network status: `Active` or `Inactive` |

## Examples

### Minimum — AllowOnlyApprovedOutbound with Entra ID egress

```yaml
azure_foundry_managed_networks:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    isolation_mode: AllowOnlyApprovedOutbound
    outbound_rules:
      entra_id:
        type: ServiceTag
        service_tag: AzureActiveDirectory
        service_tag_action: Allow
        service_tag_protocol: TCP
        service_tag_port_ranges: "443"
```

### AllowInternetOutbound (dev/test)

```yaml
azure_foundry_managed_networks:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    isolation_mode: AllowInternetOutbound
    managed_network_kind: V2
    firewall_sku: Basic
```

### With private endpoint to Storage and FQDN rule

```yaml
azure_foundry_managed_networks:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    isolation_mode: AllowOnlyApprovedOutbound
    managed_network_kind: V2
    firewall_sku: Standard
    outbound_rules:
      entra_id:
        type: ServiceTag
        service_tag: AzureActiveDirectory
        service_tag_action: Allow
        service_tag_protocol: TCP
        service_tag_port_ranges: "443"
      storage_pe:
        type: PrivateEndpoint
        private_endpoint_service_resource_id: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/mystorage
        private_endpoint_subresource_target: blob
        private_endpoint_fqdns:
          - mystorage.blob.core.windows.net
      custom_api:
        type: FQDN
        fqdn_destination: "api.example.com"
```

## Dependency Chain

```
Layer 0: azure_resource_groups
Layer 1: azure_foundry_accounts  (depends on resource_groups)
Layer 3: azure_foundry_managed_networks  (depends on foundry_accounts)
Layer 4: azure_foundry_deployments  (depends on foundry_accounts)
```

Always wire `account_name` via `ref:azure_foundry_accounts.<key>.account_name` to ensure the account is created before the managed network.

## See Also

- [foundry_account module](../foundry_account/README.md) — parent account
- [foundry_deployment module](../foundry_deployment/README.md) — model deployments
- [Azure AI Foundry managed networks REST API](https://learn.microsoft.com/en-us/rest/api/cognitiveservices/accountmanagement/managed-networks)
