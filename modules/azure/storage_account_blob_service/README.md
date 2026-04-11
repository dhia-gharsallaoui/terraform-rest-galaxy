# storage_account_blob_service

Manages the blob service configuration (`blobServices/default`) for an Azure Storage Account using the `LaurentLesle/rest` provider.

**API Version:** `2025-08-01` (latest stable as of generation)  
**ARM Path:** `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/blobServices/default`

> **Singleton resource**: Azure exposes `blobServices/default` as a singleton — there is no DELETE operation. Running `terraform destroy` removes this resource from Terraform state only. The blob service configuration persists in Azure with its last applied settings.

## Features

- CORS rules configuration
- Soft delete for blobs (`deleteRetentionPolicy`) and containers (`containerDeleteRetentionPolicy`)
- Blob versioning
- Change feed (enabled/disabled, with configurable retention)
- Point-in-time restore policy
- Last access time tracking
- Automatic snapshot policy
- Default service version override

## Usage

```hcl
module "blob_service" {
  source = "./modules/azure/storage_account_blob_service"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "mystorageaccount"

  delete_retention_policy = {
    enabled = true
    days    = 7
  }

  is_versioning_enabled = true

  change_feed_enabled          = true
  change_feed_retention_in_days = 30
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `subscription_id` | `string` | yes | Azure subscription ID |
| `resource_group_name` | `string` | yes | Resource group name containing the storage account |
| `account_name` | `string` | yes | Storage account name |
| `cors_rules` | `list(object)` | no | CORS rules (allowedOrigins, allowedMethods, allowedHeaders, exposedHeaders, maxAgeInSeconds) |
| `delete_retention_policy` | `object` | no | Soft delete policy for blobs (enabled, days 1–365, allowPermanentDelete) |
| `container_delete_retention_policy` | `object` | no | Soft delete policy for containers (enabled, days 1–365) |
| `is_versioning_enabled` | `bool` | no | Enable blob versioning |
| `change_feed_enabled` | `bool` | no | Enable change feed |
| `change_feed_retention_in_days` | `number` | no | Change feed retention in days (1–146000) |
| `restore_policy_enabled` | `bool` | no | Enable point-in-time restore |
| `restore_policy_days` | `number` | no | Point-in-time restore window in days (1–365) |
| `last_access_time_tracking_enabled` | `bool` | no | Enable last access time tracking |
| `last_access_tracking_granularity_in_days` | `number` | no | Tracking granularity in days (allowed value: 1) |
| `automatic_snapshot_policy_enabled` | `bool` | no | Enable automatic snapshot policy |
| `default_service_version` | `string` | no | Default blob service version (e.g. `2020-06-12`) |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Full ARM resource ID (plan-time) |
| `api_version` | ARM API version used |
| `sku_name` | SKU name from Azure (known after apply) |
| `provisioning_state` | Provisioning state (known after apply) |
