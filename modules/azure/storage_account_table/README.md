# storage_account_table

Manages an Azure Storage Account Table using the `LaurentLesle/rest` provider against the Azure Storage REST API.

- **API version**: `2025-08-01` (latest stable as of generation)
- **ARM path**: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/tableServices/default/tables/{tableName}`
- **Operations**: PUT (create/update), GET (read), DELETE — full CRUD lifecycle

## Features

- Table creation and management within a storage account
- Stored access policies (signedIdentifiers) with start/expiry/permission control
- Plan-time known `id` and `name` outputs for downstream references

## Usage

### Minimum

```hcl
module "table" {
  source = "./modules/azure/storage_account_table"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "stmyapp001"
  table_name          = "MyTable"
}
```

### Complete (with signed identifiers)

```hcl
module "table_complete" {
  source = "./modules/azure/storage_account_table"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "stmyapp001"
  table_name          = "EventsTable"
  signed_identifiers = [
    {
      id = "readpolicy"
      access_policy = {
        start_time  = "2025-01-01T00:00:00Z"
        expiry_time = "2026-01-01T00:00:00Z"
        permission  = "r"
      }
    }
  ]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `subscription_id` | `string` | yes | Azure subscription ID |
| `resource_group_name` | `string` | yes | Resource group name |
| `account_name` | `string` | yes | Storage account name |
| `table_name` | `string` | yes | Table name (3–63 alphanumeric, must start with a letter) |
| `signed_identifiers` | `list(object)` | no | Stored access policies |
| `check_existance` | `bool` | no | Import existing resource into state |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Full ARM resource ID (plan-time known) |
| `name` | Table name (plan-time known) |
| `api_version` | API version string |
| `table_name_from_api` | Table name as returned by the Azure API (known after apply) |
