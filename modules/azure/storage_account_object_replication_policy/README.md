# storage_account_object_replication_policy

Manages a Storage Account Object Replication Policy using the `LaurentLesle/rest` Terraform provider.

Object replication asynchronously copies block blobs between storage accounts. This module creates the replication policy on the **destination** account. A corresponding policy (using the assigned `policy_id` and `rule_id` values from outputs) must also be set on the source account.

- **API version**: `2025-08-01` (latest stable as of module generation)
- **ARM path**: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/objectReplicationPolicies/{objectReplicationPolicyId}`
- **Operations**: PUT (create/update), GET (read), DELETE

## Prerequisites

Both source and destination storage accounts must have:
- `kind = StorageV2` or `BlobStorage`
- Blob versioning enabled (configure via the blob service properties)
- Blob change feed enabled on the source account

## Creation workflow

1. Create the destination policy with `policy_id = "default"` — Azure returns the assigned `policy_id` and per-rule `ruleId` values in the outputs.
2. Create the source policy using the `policy_id` output from step 1, and set `rule_id` for each rule using values from the `rules` output.

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | `string` | yes | Subscription containing the destination account |
| `resource_group_name` | `string` | yes | Resource group containing the destination account |
| `account_name` | `string` | yes | Destination storage account name |
| `source_account` | `string` | yes | Full ARM resource ID of the source storage account |
| `policy_id` | `string` | no | Policy ID; use `"default"` for new policies |
| `rules` | `list(object)` | yes | Replication rules mapping source to destination containers |
| `metrics_enabled` | `bool` | no | Enable replication metrics |
| `priority_replication_enabled` | `bool` | no | Enable priority replication |
| `tags_replication_enabled` | `bool` | no | Enable tag replication |
| `check_existance` | `bool` | no | Import existing resource into state instead of creating |

## Outputs

| Name | Description |
|---|---|
| `id` | Full ARM resource ID (plan-time) |
| `api_version` | ARM API version used |
| `policy_id` | Azure-assigned policy ID (API-sourced) |
| `enabled_time` | Datetime when policy was enabled (API-sourced) |
| `rules` | Rules with auto-assigned ruleId values (API-sourced) |

## Example Usage

```hcl
module "replication_policy" {
  source = "./modules/azure/storage_account_object_replication_policy"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-data"
  account_name        = "mydestinationstorage"
  source_account      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-src/providers/Microsoft.Storage/storageAccounts/mysourcestorage"
  policy_id           = "default"
  rules = [
    {
      source_container      = "source-data"
      destination_container = "replicated-data"
      min_creation_time     = "2024-01-01T00:00:00Z"
    }
  ]
}
```
