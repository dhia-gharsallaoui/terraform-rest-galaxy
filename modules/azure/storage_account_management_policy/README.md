# storage_account_management_policy

Manages the lifecycle management policy (`managementPolicies/default`) for an Azure Storage Account using the `LaurentLesle/rest` Terraform provider.

Only one management policy is permitted per storage account, and it must always be named `default`. The policy contains an array of lifecycle rules that automate tiering and deletion of blobs, snapshots, and versions based on age or last-access conditions.

## API

- **Spec path:** `storage/resource-manager/Microsoft.Storage`
- **API version:** `2025-08-01` (latest stable as of generation)
- **Operations:** PUT (create/update), GET (read), DELETE

## Usage

### Minimum — delete blobs not accessed in 90 days

```hcl
module "lifecycle_policy" {
  source = "./modules/azure/storage_account_management_policy"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-data"
  account_name        = "mydatalake"

  rules = [
    {
      name = "delete-cold"
      filters = {
        blob_types = ["blockBlob"]
      }
      actions = {
        base_blob = {
          delete_after_days_since_last_access_time_greater_than = 90
        }
      }
    }
  ]
}
```

### Complete — multi-tier data lake lifecycle

```hcl
module "lifecycle_policy" {
  source = "./modules/azure/storage_account_management_policy"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-datalake"
  account_name        = "mydatalake"

  rules = [
    {
      name    = "datalake-hot-to-cool"
      enabled = true
      filters = {
        blob_types   = ["blockBlob"]
        prefix_match = ["raw/", "processed/"]
      }
      actions = {
        base_blob = {
          tier_to_cool_after_days_since_modification_greater_than    = 30
          tier_to_archive_after_days_since_modification_greater_than = 180
          delete_after_days_since_modification_greater_than          = 1825
        }
        snapshot = {
          change_tier_to_cool_after_days_since_creation    = 30
          change_tier_to_archive_after_days_since_creation = 90
          delete_after_days_since_creation_greater_than    = 365
        }
        version = {
          change_tier_to_cool_after_days_since_creation    = 30
          change_tier_to_archive_after_days_since_creation = 90
          delete_after_days_since_creation                 = 365
        }
      }
    }
  ]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `subscription_id` | `string` | yes | Azure subscription ID |
| `resource_group_name` | `string` | yes | Resource group containing the storage account |
| `account_name` | `string` | yes | Storage account name |
| `rules` | `list(object)` | yes | List of lifecycle management rules |
| `check_existance` | `bool` | no | When true, import existing policy into state instead of failing |

### Rule object structure

Each rule in the `rules` list supports:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | yes | Unique rule name |
| `enabled` | `bool` | no | Whether the rule is active (default: `true`) |
| `filters.blob_types` | `list(string)` | yes | Blob types to match: `blockBlob`, `appendBlob` |
| `filters.prefix_match` | `list(string)` | no | Container or path prefix filters |
| `filters.blob_index_match` | `list(object)` | no | Tag-based index filters |
| `actions.base_blob` | `object` | no | Actions for base blobs |
| `actions.snapshot` | `object` | no | Actions for blob snapshots |
| `actions.version` | `object` | no | Actions for blob versions |

## Outputs

| Name | Type | Plan-time | Description |
|------|------|-----------|-------------|
| `id` | `string` | yes | Full ARM resource ID |
| `api_version` | `string` | yes | ARM API version used |
| `last_modified_time` | `string` | no | Timestamp of last policy modification |
