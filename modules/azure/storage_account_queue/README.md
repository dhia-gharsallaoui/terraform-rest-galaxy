# storage_account_queue

Manages an Azure Storage Account Queue using the `LaurentLesle/rest` provider against the Azure Storage REST API.

- **API version**: `2025-08-01` (latest stable as of generation)
- **ARM path**: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/queueServices/default/queues/{queueName}`
- **Operations**: PUT (create/update), GET (read), DELETE — full CRUD lifecycle

## Features

- Queue creation and management within a storage account
- Custom metadata key-value pairs
- Plan-time known `id` and `name` outputs for downstream references

## Usage

### Minimum

```hcl
module "queue" {
  source = "./modules/azure/storage_account_queue"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "stmyapp001"
  queue_name          = "my-queue"
}
```

### Complete (with metadata)

```hcl
module "queue_complete" {
  source = "./modules/azure/storage_account_queue"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "stmyapp001"
  queue_name          = "events-queue"
  metadata = {
    environment = "production"
    team        = "platform"
    purpose     = "event-processing"
  }
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `subscription_id` | `string` | yes | Azure subscription ID |
| `resource_group_name` | `string` | yes | Resource group name |
| `account_name` | `string` | yes | Storage account name |
| `queue_name` | `string` | yes | Queue name (3–63 lowercase alphanumeric or hyphens) |
| `metadata` | `map(string)` | no | Custom metadata key-value pairs |
| `check_existance` | `bool` | no | Import existing resource into state |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Full ARM resource ID (plan-time known) |
| `name` | Queue name (plan-time known) |
| `api_version` | API version string |
| `approximate_message_count` | Approximate number of messages in the queue (known after apply) |
