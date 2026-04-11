# Azure AI Foundry Account Module

Manages an Azure AI Foundry account (`Microsoft.CognitiveServices/accounts`, `kind=AIFoundry`).

> **Hero module:** Full schema coverage with SOC2-secure defaults, CMK encryption support, managed identity wiring, and complete documentation.

## Overview

An Azure AI Foundry account is the top-level hub resource for the AI Foundry v2 experience. It hosts:
- Model deployments (via the `foundry_deployment` child module)
- Foundry projects (child resources for team isolation)
- Managed virtual network isolation (via the `foundry_managed_network` child module)
- Agent compute, RAI monitoring, and AML workspace integration

> **Important:** Azure AI Foundry v2 uses `Microsoft.CognitiveServices/accounts` with `kind=AIFoundry`. Do NOT confuse with:
> - `Microsoft.MachineLearningServices/workspaces` — legacy Azure AI Studio / Hub (v1)
> - `Microsoft.CognitiveServices/accounts` with `kind=OpenAI` — Azure OpenAI standalone resource

## API Version

`2025-04-01-preview` — latest available.

## SOC2 Defaults

This module ships with security-hardened defaults:

| Setting | Default | Reason |
|---|---|---|
| `public_network_access` | `Disabled` | Prevents direct internet access |
| `disable_local_auth` | `true` | Enforces Azure AD authentication only |
| `network_acls_default_action` | `Deny` | Blocks unapproved network traffic by default |

Set `public_network_access = "Enabled"` and `network_acls_default_action = "Allow"` only for development environments.

## Identity Reference

| Type | Description |
|---|---|
| `SystemAssigned` | Azure-managed identity tied to the account lifecycle — recommended for most deployments |
| `UserAssigned` | Bring-your-own managed identity — required for CMK encryption |
| `SystemAssigned, UserAssigned` | Both types simultaneously |
| `None` | No managed identity |

## SKU Reference

| SKU | Use case |
|---|---|
| `S0` | Standard pay-as-you-go — the only generally available SKU for Foundry accounts |

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `subscription_id` | string | yes | — | Azure subscription ID |
| `resource_group_name` | string | yes | — | Resource group name |
| `account_name` | string | yes | — | Account name (2–64 chars, alphanumeric/hyphen/underscore/dot) |
| `location` | string | yes | — | Azure region |
| `sku_name` | string | yes | — | SKU name (use `S0`) |
| `kind` | string | no | `AIFoundry` | Must be `AIFoundry` — locked by validation |
| `sku_capacity` | number | no | null | Optional scale capacity (must be > 0) |
| `sku_tier` | string | no | null | Basic, Enterprise, Free, Premium, or Standard |
| `identity_type` | string | no | null | None, SystemAssigned, UserAssigned, or `SystemAssigned, UserAssigned` |
| `identity_user_assigned_identity_ids` | list(string) | no | null | User-assigned identity resource IDs |
| `public_network_access` | string | no | `Disabled` | `Enabled` or `Disabled` |
| `network_acls_default_action` | string | no | `Deny` | `Allow` or `Deny` |
| `network_acls_bypass` | string | no | null | `AzureServices` or `None` |
| `network_acls_ip_rules` | list(string) | no | null | Allowed IPv4 CIDR ranges |
| `network_acls_virtual_network_rules` | list(object) | no | null | Allowed subnet rules |
| `network_injections` | list(object) | no | null | Agent compute subnet injections (scenario: `agent` or `none`) |
| `restrict_outbound_network_access` | bool | no | null | Restrict all outbound traffic |
| `allowed_fqdn_list` | list(string) | no | null | Allowed outbound FQDNs |
| `disable_local_auth` | bool | no | `true` | Disable API key auth; enforce Azure AD |
| `custom_sub_domain_name` | string | no | null | Custom endpoint subdomain (globally unique) |
| `allow_project_management` | bool | no | null | Enable Foundry project child resources |
| `associated_projects` | list(string) | no | null | Associated project names |
| `default_project` | string | no | null | Default project name for data plane calls |
| `encryption_key_source` | string | no | null | `Microsoft.CognitiveServices` (MMK) or `Microsoft.KeyVault` (CMK) |
| `encryption_key_vault_uri` | string | no | null | Key Vault URI for CMK |
| `encryption_key_name` | string | no | null | Encryption key name for CMK |
| `encryption_key_version` | string | no | null | Key version (null = auto-rotate) |
| `encryption_identity_client_id` | string | no | null | Identity client ID for Key Vault access |
| `stored_completions_disabled` | bool | no | null | Disable completion storage |
| `dynamic_throttling_enabled` | bool | no | null | Enable dynamic throttling |
| `user_owned_storage` | list(object) | no | null | Associated storage accounts |
| `rai_monitor_config_storage_resource_id` | string | no | null | Storage for RAI monitoring data |
| `rai_monitor_config_identity_client_id` | string | no | null | Identity for RAI monitoring storage access |
| `aml_workspace_resource_id` | string | no | null | AML workspace to associate |
| `aml_workspace_identity_client_id` | string | no | null | Identity for AML workspace access |
| `restore` | bool | no | null | Restore a soft-deleted account with the same name |
| `tags` | map(string) | no | null | Resource tags |
| `check_existance` | bool | no | false | Import existing account into state if found |

## Outputs

| Name | Plan-time | Description |
|---|---|---|
| `id` | yes | Full ARM resource ID |
| `api_version` | yes | ARM API version in use |
| `account_name` | yes | Account name (echoes input) |
| `location` | yes | Azure region (echoes input) |
| `resource_group_name` | yes | Resource group (echoes input) |
| `kind` | yes | Account kind (echoes input) |
| `sku_name` | yes | SKU name (echoes input) |
| `provisioning_state` | after apply | Provisioning state (Succeeded, etc.) |
| `endpoint` | after apply | HTTPS endpoint URL |
| `internal_id` | after apply | Azure-assigned internal account ID |
| `date_created` | after apply | UTC creation timestamp |
| `principal_id` | after apply | System-assigned identity principal ID |
| `tenant_id_identity` | after apply | System-assigned identity tenant ID |

## Examples

### Minimum — SOC2 compliant

```yaml
azure_foundry_accounts:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: my-foundry-hub
    sku_name: S0
```

### With system-assigned identity and project management

```yaml
azure_foundry_accounts:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: my-foundry-hub
    sku_name: S0
    identity_type: SystemAssigned
    allow_project_management: true
    public_network_access: Disabled
    disable_local_auth: true
    network_acls_default_action: Deny
```

### With customer-managed key (CMK) encryption

CMK requires a user-assigned identity with `Key Vault Crypto User` role on the vault:

```yaml
azure_foundry_accounts:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: my-foundry-hub
    sku_name: S0
    identity_type: UserAssigned
    identity_user_assigned_identity_ids:
      - /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-uami
    encryption_key_source: Microsoft.KeyVault
    encryption_key_vault_uri: https://my-kv.vault.azure.net/
    encryption_key_name: foundry-cmk
    encryption_identity_client_id: 00000000-0000-0000-0000-000000000001
```

### With network ACL rules (dev/test with public access)

```yaml
azure_foundry_accounts:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: my-foundry-hub
    sku_name: S0
    public_network_access: Enabled
    network_acls_default_action: Deny
    network_acls_bypass: AzureServices
    network_acls_ip_rules:
      - 203.0.113.0/24
```

### With managed VNet and deployments (full stack)

```yaml
azure_resource_groups:
  foundry:
    location: francecentral

azure_resource_provider_features:
  foundry_managed_vnet:
    provider_namespace: Microsoft.CognitiveServices
    feature_name: AI.ManagedVnetPreview
    state: Registered

azure_foundry_accounts:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: my-foundry-hub
    sku_name: S0
    identity_type: SystemAssigned
    allow_project_management: true
    public_network_access: Disabled
    disable_local_auth: true
    network_acls_default_action: Deny

azure_foundry_managed_networks:
  main:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    isolation_mode: AllowOnlyApprovedOutbound
    managed_network_kind: V2

azure_foundry_deployments:
  gpt4o:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    deployment_name: gpt-4o
    model_format: OpenAI
    model_name: gpt-4o
    sku_name: GlobalStandard
    sku_capacity: 100
```

## CMK Encryption Prerequisites

When using `encryption_key_source = "Microsoft.KeyVault"`:

1. Create a user-assigned managed identity
2. Grant it the `Key Vault Crypto User` role on the Key Vault
3. Pass its client ID as `encryption_identity_client_id`
4. Set `identity_type = "UserAssigned"` (or `"SystemAssigned, UserAssigned"`)
5. Include its resource ID in `identity_user_assigned_identity_ids`

## Dependency Chain

```
Layer 0: azure_resource_groups
Layer 1: azure_foundry_accounts  (depends on resource_groups)
Layer 3: azure_foundry_managed_networks  (depends on foundry_accounts)
Layer 4: azure_foundry_deployments  (depends on foundry_accounts)
```

Always wire `resource_group_name` and `location` via `ref:azure_resource_groups.<key>.<attr>` to ensure the resource group is created before the account.

## See Also

- [foundry_managed_network module](../foundry_managed_network/README.md) — managed VNet for egress control
- [foundry_deployment module](../foundry_deployment/README.md) — model deployments under this account
- [Azure AI Foundry accounts REST API](https://learn.microsoft.com/en-us/rest/api/cognitiveservices/accountmanagement/accounts/create)
