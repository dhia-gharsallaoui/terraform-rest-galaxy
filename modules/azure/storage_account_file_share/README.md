# storage_account_file_share

Manages an Azure Storage Account File Share using the `LaurentLesle/rest` provider against the Azure Storage REST API.

- **API version**: `2025-08-01` (latest stable as of generation)
- **ARM path**: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/fileServices/default/shares/{shareName}`
- **Operations**: PUT (create/update), GET (read), DELETE — full CRUD lifecycle

## Features

- Configurable share quota (1–102400 GiB)
- Access tier selection (TransactionOptimized, Hot, Cool, Premium)
- Protocol selection: SMB or NFS (immutable after creation — triggers destroy+create on change)
- NFS root squash support (NoRootSquash, RootSquash, AllSquash)
- Custom metadata
- Stored access policies (signedIdentifiers) with granular start/expiry/permission control

## Usage

### Minimum

```hcl
module "file_share" {
  source = "./modules/azure/storage_account_file_share"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "stmyapp001"
  share_name          = "myshare"
  share_quota         = 100
}
```

### NFS share

```hcl
module "file_share_nfs" {
  source = "./modules/azure/storage_account_file_share"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "stmyapp001"
  share_name          = "nfsshare"
  share_quota         = 1024
  enabled_protocols   = "NFS"
  root_squash         = "RootSquash"
}
```

### Complete (with signed identifiers)

```hcl
module "file_share_complete" {
  source = "./modules/azure/storage_account_file_share"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "stmyapp001"
  share_name          = "completeshare"
  share_quota         = 512
  access_tier         = "Hot"
  enabled_protocols   = "SMB"
  metadata = {
    environment = "production"
    team        = "platform"
  }
  signed_identifiers = [
    {
      id = "policy1"
      access_policy = {
        start_time  = "2025-01-01T00:00:00Z"
        expiry_time = "2026-01-01T00:00:00Z"
        permission  = "rw"
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
| `share_name` | `string` | yes | File share name (3–63 lowercase alphanumeric or hyphens) |
| `share_quota` | `number` | yes | Share size in GiB (1–102400) |
| `access_tier` | `string` | no | Access tier: TransactionOptimized, Hot, Cool, Premium |
| `enabled_protocols` | `string` | no | SMB or NFS (immutable after creation) |
| `root_squash` | `string` | no | NFS root squash: NoRootSquash, RootSquash, AllSquash |
| `metadata` | `map(string)` | no | Custom metadata key-value pairs |
| `signed_identifiers` | `list(object)` | no | Stored access policies |
| `check_existance` | `bool` | no | Import existing resource into state |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Full ARM resource ID (plan-time known) |
| `name` | File share name (plan-time known) |
| `api_version` | API version string |
| `provisioning_state` | Provisioning state (known after apply) |
| `enabled_protocols` | Authentication protocol (known after apply) |
| `access_tier` | Effective access tier (known after apply) |
| `share_quota` | Provisioned share size in GiB (known after apply) |
