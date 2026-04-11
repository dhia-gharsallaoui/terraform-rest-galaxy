# storage_account_encryption_scope

Manages an encryption scope for an Azure Storage Account using the `LaurentLesle/rest` Terraform provider.

Encryption scopes allow per-container or per-blob encryption with a distinct key from the storage account's default key. Scopes may use either platform-managed keys (`Microsoft.Storage`) or customer-managed keys stored in Azure Key Vault (`Microsoft.KeyVault`).

> **Note:** Azure does not support deleting encryption scopes via the API. To decommission a scope, set `state = "Disabled"`. The resource is intentionally retained in ARM.

## API

- **Spec path:** `storage/resource-manager/Microsoft.Storage`
- **API version:** `2025-08-01` (latest stable as of generation)
- **Operations:** PUT (create), GET (read), PATCH (update) — no DELETE

## Usage

### Minimum — platform-managed key

```hcl
module "encryption_scope" {
  source = "./modules/azure/storage_account_encryption_scope"

  subscription_id       = "00000000-0000-0000-0000-000000000000"
  resource_group_name   = "rg-storage"
  account_name          = "mystorageaccount"
  encryption_scope_name = "myencscope"
  encryption_source     = "Microsoft.Storage"
}
```

### Complete — customer-managed key with infrastructure encryption

```hcl
module "encryption_scope" {
  source = "./modules/azure/storage_account_encryption_scope"

  subscription_id                   = "00000000-0000-0000-0000-000000000000"
  resource_group_name               = "rg-storage"
  account_name                      = "mystorageaccount"
  encryption_scope_name             = "cmkscope"
  encryption_source                 = "Microsoft.KeyVault"
  key_vault_key_uri                 = "https://myvault.vault.azure.net/keys/mykey/abc123"
  require_infrastructure_encryption = true
  state                             = "Enabled"
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `subscription_id` | `string` | yes | Azure subscription ID |
| `resource_group_name` | `string` | yes | Resource group name |
| `account_name` | `string` | yes | Storage account name |
| `encryption_scope_name` | `string` | yes | Encryption scope name (3–63 chars, alphanumeric + hyphens) |
| `encryption_source` | `string` | yes | Key source: `Microsoft.Storage` or `Microsoft.KeyVault` |
| `key_vault_uri` | `string` | no | Key Vault URI (informational; use `key_vault_key_uri` for CMK) |
| `key_vault_key_uri` | `string` | no | Full URI of the Key Vault key (required for CMK scopes) |
| `require_infrastructure_encryption` | `bool` | no | Enable double encryption at infrastructure level |
| `state` | `string` | no | `Enabled` or `Disabled` (default: `Enabled`) |
| `check_existance` | `bool` | no | Import existing scope instead of failing |

## Outputs

| Name | Type | Plan-time | Description |
|------|------|-----------|-------------|
| `id` | `string` | yes | Full ARM resource ID |
| `name` | `string` | yes | Encryption scope name (echoes input) |
| `api_version` | `string` | yes | ARM API version used |
| `state` | `string` | no | Current state: Enabled or Disabled |
| `created_on` | `string` | no | Creation timestamp |
| `last_modified_time` | `string` | no | Last modification timestamp |
| `provisioning_state` | `string` | no | ARM provisioning state |
