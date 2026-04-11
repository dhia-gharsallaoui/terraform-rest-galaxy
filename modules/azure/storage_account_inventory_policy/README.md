# storage_account_inventory_policy

Manages the Blob Inventory Policy for a Storage Account using the `LaurentLesle/rest` Terraform provider.

The blob inventory policy generates periodic inventory reports (CSV or Parquet) for blobs and containers, written to a specified destination container. This is a singleton resource — each storage account has exactly one inventory policy named `default`.

- **API version**: `2025-08-01` (latest stable as of module generation)
- **ARM path**: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/inventoryPolicies/default`
- **Operations**: PUT (create/update), GET (read), DELETE

## Prerequisites

- The destination container referenced in each rule must exist before the policy is applied.
- Blob versioning must be enabled on the storage account when `include_blob_versions = true`.
- Blob soft delete must be enabled when `include_deleted = true` for Blob object type.

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | `string` | yes | Azure subscription ID |
| `resource_group_name` | `string` | yes | Resource group containing the storage account |
| `account_name` | `string` | yes | Storage account name |
| `rules` | `list(object)` | yes | Inventory policy rules (see variable description for schema) |
| `check_existance` | `bool` | no | Import existing resource into state instead of creating |

## Outputs

| Name | Description |
|---|---|
| `id` | Full ARM resource ID (plan-time) |
| `api_version` | ARM API version used |
| `last_modified_time` | When the policy was last modified (API-sourced) |

## Example Usage

```hcl
module "inventory_policy" {
  source = "./modules/azure/storage_account_inventory_policy"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-data"
  account_name        = "mydatalake"
  rules = [
    {
      name          = "weekly-blob-inventory"
      destination   = "inventory-reports"
      schedule      = "Weekly"
      object_type   = "Blob"
      format        = "Parquet"
      schema_fields = ["Name", "Creation-Time", "Content-Length", "BlobType", "AccessTier"]
    }
  ]
}
```
