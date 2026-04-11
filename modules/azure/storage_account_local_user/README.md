# storage_account_local_user

Manages a Storage Account Local User for SFTP (SSH File Transfer Protocol) and NFS access using the `LaurentLesle/rest` Terraform provider.

Local users are the identity construct for SFTP and NFSv3 access to Azure Blob Storage and Azure Files. Each user can be granted permission scopes on specific containers or file shares, optionally configured with SSH keys for SFTP authentication.

- **API version**: `2025-08-01` (latest stable as of module generation)
- **ARM path**: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/localUsers/{username}`
- **Operations**: PUT (create/update), GET (read), DELETE

## Prerequisites

The parent storage account must have the following properties enabled:
- `is_hns_enabled = true` — Hierarchical Namespace (Data Lake Gen2)
- `is_sftp_enabled = true` — SFTP protocol support
- `is_local_user_enabled = true` — Local user authentication

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | `string` | yes | Azure subscription ID |
| `resource_group_name` | `string` | yes | Resource group containing the storage account |
| `account_name` | `string` | yes | Storage account name |
| `username` | `string` | yes | Local user name (3–64 chars, lowercase alphanumeric + hyphens) |
| `permission_scopes` | `list(object)` | yes | Permission scopes: service (blob/file), resource_name, permissions (rwdlcmxop chars) |
| `home_directory` | `string` | no | Home directory path within the storage account |
| `ssh_authorized_keys` | `list(object)` | no | SSH public keys for SFTP authentication |
| `has_ssh_password` | `bool` | no | Set to false to remove an existing SSH password |
| `allow_acl_authorization` | `bool` | no | Allow ACL (POSIX) authorization for this user |
| `group_id` | `number` | no | Group identifier for NFSv3 local users |
| `extended_groups` | `list(number)` | no | Supplementary group memberships (NFSv3 only) |
| `check_existance` | `bool` | no | Import existing resource into state instead of creating |

## Outputs

| Name | Description |
|---|---|
| `id` | Full ARM resource ID (plan-time) |
| `name` | Username (plan-time, echoes input) |
| `api_version` | ARM API version used |
| `has_ssh_key` | Whether an SSH key exists (API-sourced) |
| `has_ssh_password` | Whether an SSH password exists (API-sourced) |
| `sid` | Security Identifier assigned by Azure (API-sourced) |
| `user_id` | Numeric user ID assigned by Azure (API-sourced) |

## Example Usage

```hcl
module "sftp_user" {
  source = "./modules/azure/storage_account_local_user"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-data"
  account_name        = "mydatalakestorage"
  username            = "sftp-upload"
  permission_scopes = [
    {
      service       = "blob"
      resource_name = "uploads"
      permissions   = "rwdl"
    }
  ]
}
```
