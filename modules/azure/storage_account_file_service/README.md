# storage_account_file_service

Manages the file service configuration (`fileServices/default`) for an Azure Storage Account using the `LaurentLesle/rest` provider.

**API Version:** `2025-08-01` (latest stable as of generation)  
**ARM Path:** `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/fileServices/default`

> **Singleton resource**: Azure exposes `fileServices/default` as a singleton — there is no DELETE operation. Running `terraform destroy` removes this resource from Terraform state only. The file service configuration persists in Azure with its last applied settings.

## Features

- CORS rules configuration
- Share soft delete (`shareDeleteRetentionPolicy`)
- SMB protocol settings: versions, authentication methods, Kerberos ticket encryption, channel encryption, multichannel
- NFS protocol settings: NFSv3 and NFSv4.1

## Usage

```hcl
module "file_service" {
  source = "./modules/azure/storage_account_file_service"

  subscription_id     = "00000000-0000-0000-0000-000000000000"
  resource_group_name = "rg-myapp"
  account_name        = "mystorageaccount"

  share_delete_retention_policy = {
    enabled = true
    days    = 7
  }

  smb_versions               = ["SMB3.0", "SMB3.1.1"]
  smb_authentication_methods = ["Kerberos"]
  smb_channel_encryption     = ["AES-128-GCM", "AES-256-GCM"]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `subscription_id` | `string` | yes | Azure subscription ID |
| `resource_group_name` | `string` | yes | Resource group name containing the storage account |
| `account_name` | `string` | yes | Storage account name |
| `cors_rules` | `list(object)` | no | CORS rules (allowedOrigins, allowedMethods, allowedHeaders, exposedHeaders, maxAgeInSeconds) |
| `share_delete_retention_policy` | `object` | no | Soft delete policy for shares (enabled, days 1–365) |
| `smb_versions` | `list(string)` | no | Allowed SMB versions: SMB2.1, SMB3.0, SMB3.1.1 |
| `smb_authentication_methods` | `list(string)` | no | Allowed auth methods: NTLMv2, Kerberos |
| `smb_kerberos_ticket_encryption` | `list(string)` | no | Kerberos ticket encryption: RC4-HMAC, AES-256 |
| `smb_channel_encryption` | `list(string)` | no | Channel encryption: AES-128-CCM, AES-128-GCM, AES-256-GCM |
| `smb_multichannel_enabled` | `bool` | no | Enable SMB Multichannel (Premium FileStorage only) |
| `nfs_v3_enabled` | `bool` | no | Enable NFS 3.0 protocol support |
| `nfs_v4_1_enabled` | `bool` | no | Enable NFS 4.1 protocol support |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Full ARM resource ID (plan-time) |
| `api_version` | ARM API version used |
| `provisioning_state` | Provisioning state (known after apply) |
