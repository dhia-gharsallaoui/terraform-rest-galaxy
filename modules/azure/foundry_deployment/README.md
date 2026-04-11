# Azure AI Foundry Deployment Module

Manages a model deployment on an Azure AI Foundry account (`Microsoft.CognitiveServices/accounts/deployments`).

> **Hero module:** Full schema coverage with plan-time model availability validation, typed SKU validation, and complete documentation.

## Overview

A Foundry deployment provisions a specific AI model for inference under a Foundry account. Each deployment:
- Targets a specific model (e.g. `gpt-4o`, `text-embedding-3-large`)
- Allocates capacity (TPM for Standard, PTU for Provisioned)
- Controls version upgrade behaviour
- Optionally applies a Responsible AI content filtering policy

**Plan-time model availability check** — a `data "rest_resource"` source queries
`GET .../providers/Microsoft.CognitiveServices/locations/{location}/models` before
the deployment is created. If the model is not available in the target region,
`terraform plan` fails immediately with a CLI command to list available models.

## API Version

`2025-09-01` — **stable GA**.

## SKU Reference

| SKU name | Billing | Use case |
|---|---|---|
| `GlobalStandard` | Pay-per-token, global routing | Production — recommended default |
| `Standard` | Pay-per-token, regional | Data-residency requirements |
| `DataZoneStandard` | Pay-per-token, data-zone routing | Data-zone compliance |
| `ProvisionedManaged` | Reserved PTU, regional | Predictable latency, high throughput |
| `DataZoneProvisionedManaged` | Reserved PTU, data-zone | Provisioned + data-zone |
| `OnDemand` | On-demand capacity | Burst workloads |

## Version Upgrade Options

| Option | Behaviour |
|---|---|
| `OnceNewDefaultVersionAvailable` | Auto-upgrades when a new default is released (default) |
| `OnceCurrentVersionExpired` | Stays pinned until EOL, then upgrades |
| `NoAutoUpgrade` | Never auto-upgrades — manual version management required |

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `subscription_id` | string | yes | — | Azure subscription ID |
| `resource_group_name` | string | yes | — | Resource group of the parent account |
| `account_name` | string | yes | — | Parent Foundry account name |
| `location` | string | yes | — | Azure region (used for model availability check) |
| `deployment_name` | string | yes | — | Name of the deployment (endpoint identifier) |
| `model_format` | string | yes | — | Model format/provider (e.g. `OpenAI`) |
| `model_name` | string | yes | — | Model name (e.g. `gpt-4o`) |
| `sku_name` | string | yes | — | Deployment SKU (see SKU Reference above) |
| `model_version` | string | no | null | Pinned model version (null = Microsoft default) |
| `model_publisher` | string | no | null | Model publisher (for catalog models) |
| `model_source` | string | no | null | Custom model source URI |
| `model_source_account` | string | no | null | Source account for cross-account deployment |
| `sku_capacity` | number | no | null | Capacity in TPM (Standard) or PTU (Provisioned) |
| `version_upgrade_option` | string | no | `OnceNewDefaultVersionAvailable` | Auto-upgrade behaviour |
| `rai_policy_name` | string | no | null | Content filtering policy name |
| `scale_type` | string | no | null | Scale type: `Standard` or `Manual` |
| `scale_capacity` | number | no | null | Scale capacity (used with scale_type) |
| `capacity_settings_designated_capacity` | number | no | null | Reserved capacity for multi-deployment sharing |
| `capacity_settings_priority` | number | no | null | Priority for capacity allocation |
| `parent_deployment_name` | string | no | null | Parent deployment for hierarchical config |
| `spillover_deployment_name` | string | no | null | Fallback deployment for overflow traffic |
| `tags` | map(string) | no | null | Resource tags |
| `check_existance` | bool | no | false | Import existing deployment if found |

## Outputs

| Name | Plan-time | Description |
|---|---|---|
| `id` | yes | Full ARM resource ID |
| `deployment_name` | yes | Deployment name (echoes input) |
| `account_name` | yes | Parent account name (echoes input) |
| `resource_group_name` | yes | Resource group name (echoes input) |
| `location` | yes | Azure region (echoes input) |
| `model_name` | yes | Deployed model name (echoes input) |
| `model_format` | yes | Model format (echoes input) |
| `sku_name` | yes | SKU name (echoes input) |
| `provisioning_state` | after apply | Provisioning state (Succeeded, etc.) |
| `model_version_deployed` | after apply | Actual deployed version (may differ if version was null) |
| `version_upgrade_option` | after apply | Version upgrade option as confirmed by Azure |
| `sku_capacity_deployed` | after apply | Actual capacity allocated by Azure |

## Examples

### Minimum — GPT-4o GlobalStandard

```yaml
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

### Pinned version with spillover

```yaml
azure_foundry_deployments:
  gpt4o_primary:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    deployment_name: gpt-4o-primary
    model_format: OpenAI
    model_name: gpt-4o
    model_version: "2024-08-06"
    sku_name: GlobalStandard
    sku_capacity: 200
    version_upgrade_option: NoAutoUpgrade
    spillover_deployment_name: gpt-4o-fallback

  gpt4o_fallback:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    deployment_name: gpt-4o-fallback
    model_format: OpenAI
    model_name: gpt-4o
    sku_name: Standard
    sku_capacity: 50
    version_upgrade_option: NoAutoUpgrade
```

### Embeddings

```yaml
azure_foundry_deployments:
  embeddings:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    deployment_name: text-embedding-3-large
    model_format: OpenAI
    model_name: text-embedding-3-large
    sku_name: Standard
    sku_capacity: 50
    version_upgrade_option: NoAutoUpgrade
```

### Provisioned Managed (PTU)

```yaml
azure_foundry_deployments:
  gpt4o_ptu:
    resource_group_name: ref:azure_resource_groups.foundry.resource_group_name
    location: ref:azure_resource_groups.foundry.location
    account_name: ref:azure_foundry_accounts.main.account_name
    deployment_name: gpt-4o-ptu
    model_format: OpenAI
    model_name: gpt-4o
    model_version: "2024-08-06"
    sku_name: ProvisionedManaged
    sku_capacity: 300
    version_upgrade_option: NoAutoUpgrade
```

## Model Availability

List models available in a region:

```bash
az rest --method GET \
  --url "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.CognitiveServices/locations/francecentral/models?api-version=2025-06-01" \
  --query "value[].{name:model.name,format:model.format,version:model.version}" \
  -o table
```

## Dependency Chain

```
Layer 0: azure_resource_groups
Layer 2: azure_foundry_accounts (depends on resource_groups)
Layer 4: azure_foundry_deployments (depends on foundry_accounts)
```

Always wire `account_name` via a `ref:azure_foundry_accounts.<key>.account_name` to
ensure Terraform applies the account before the deployment.

## See Also

- [foundry_account module](../foundry_account/README.md) — parent account
- [foundry_managed_network module](../foundry_managed_network/README.md) — managed VNet
- [Azure AI Foundry deployments REST API](https://learn.microsoft.com/en-us/rest/api/cognitiveservices/accountmanagement/deployments/create-or-update)
- [Model list REST API](https://learn.microsoft.com/en-us/rest/api/aifoundry/accountmanagement/models/list)
