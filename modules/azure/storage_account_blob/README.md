# azure/storage_account_blob

Manages a single BlockBlob in an Azure Blob Storage container using the
Blob Storage **data-plane** API (`2026-06-06`).

This module uses `LaurentLesle/rest` against the data-plane endpoint
`https://{accountName}.blob.core.windows.net`, NOT the ARM management endpoint.
See the [Architecture note](#architecture-note--data-plane-vs-arm) below.

## API Details

| Field | Value |
|---|---|
| Spec path | `storage/data-plane/Microsoft.BlobStorage` |
| API version | `2026-06-06` (stable) |
| Create / Update | `PUT /{containerName}/{blob}` with `x-ms-blob-type: BlockBlob` |
| Read | `HEAD /{containerName}/{blob}` |
| Delete | `DELETE /{containerName}/{blob}` |

## Architecture Note — Data-Plane vs ARM

Azure Blob Storage has two API surfaces:

| Surface | Base URL | Auth scope | Used for |
|---|---|---|---|
| **ARM (resource-manager)** | `https://management.azure.com` | `https://management.azure.com/.default` | Creating storage accounts, containers, configuring policies |
| **Data-plane** | `https://{accountName}.blob.core.windows.net` | `https://storage.azure.com/.default` | Reading and writing blob content |

This module targets the **data-plane** endpoint. The `provider "rest"` block used
in examples must be configured with:

```hcl
provider "rest" {
  base_url = "https://${var.account_name}.blob.core.windows.net"
  security = {
    http = {
      token = {
        token = var.storage_access_token  # storage.azure.com scope
      }
    }
  }
}
```

### Getting a storage.azure.com scoped token

```bash
# Azure CLI (local dev)
export TF_VAR_storage_access_token=$(az account get-access-token \
  --resource https://storage.azure.com \
  --query accessToken -o tsv)
```

The `storage.azure.com` scope is **different** from the ARM scope
(`management.azure.com`). You must request them separately.

### SAS token alternative

For environments where Azure AD authentication is not available, use a SAS token:

```bash
# Generate a SAS token valid for 1 hour
az storage blob generate-sas \
  --account-name myaccount \
  --container-name mycontainer \
  --name myblob \
  --permissions rwd \
  --expiry "$(date -u -d '+1 hour' '+%Y-%m-%dT%H:%MZ')" \
  --output tsv
```

Set `auth_mode = "sas"` and provide the token via `sas_token`.

## Limitations

- **BlockBlob only.** PageBlob and AppendBlob require different PUT paths and
  are not supported by this module.
- **Text/JSON content only.** The REST provider sends the body as a JSON-encoded
  object `{ "content": "<value>" }`. For binary blobs, use Azure CLI
  (`az storage blob upload`) or an Azure SDK.
- **Single storage account per provider alias.** Because the provider base URL
  encodes the account name, blobs in different storage accounts must use
  separate `provider "rest"` aliases.
- **No blob content read-back.** The `GET /{containerName}/{blob}` operation
  returns binary data. The module does not expose blob content as an output
  to avoid storing secrets in Terraform state.

## SOC2 / Compliance notes

- **Default content type** is `application/octet-stream` per the spec default.
- **Access tier** defaults to `null` (storage account default — typically Hot),
  which is the most cost-effective for frequently accessed blobs.
- **Sensitive variable** — `content` is marked `sensitive = true` to prevent
  the blob contents from appearing in plan/apply output or Terraform state diffs.
  Note: the value is still stored in Terraform state; use Azure Key Vault or
  external secret management for genuinely sensitive payloads.
- **No public access.** Blob public access depends on the container and storage
  account settings (managed by the `storage_account` and
  `storage_account_container` modules, not this one).

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `account_name` | `string` | yes | — | Storage account name (used in blob URL) |
| `container_name` | `string` | yes | — | Blob container name |
| `blob_name` | `string` | yes | — | Blob path within the container |
| `blob_type` | `string` | no | `"BlockBlob"` | Must be `BlockBlob` (only supported type) |
| `content` | `string` | no | `null` | Text/JSON blob content (sensitive) |
| `content_type` | `string` | no | `"application/octet-stream"` | MIME type |
| `metadata` | `map(string)` | no | `null` | User-defined metadata key-value pairs |
| `access_tier` | `string` | no | `null` | Hot / Cool / Cold / Archive |
| `auth_mode` | `string` | no | `"token"` | `"token"` or `"sas"` |
| `sas_token` | `string` | no | `null` | SAS token (without leading `?`) |
| `check_existance` | `bool` | no | `false` | GET before PUT (brownfield import) |

## Outputs

| Name | Description | Plan-time? |
|---|---|---|
| `id` | `/{containerName}/{blobName}` path | Yes |
| `api_version` | `2026-06-06` | Yes |
| `name` | Blob name (echoes input) | Yes |
| `container_name` | Container name (echoes input) | Yes |
| `account_name` | Account name (echoes input) | Yes |
| `blob_url` | Full `https://…` URL of the blob | Yes |
| `etag` | ETag from PUT response | After apply |
| `last_modified` | Last-modified timestamp | After apply |
| `version_id` | Blob version ID (if versioning enabled) | After apply |
| `server_encrypted` | Whether blob is server-encrypted | After apply |

## Example usage (minimum)

```hcl
provider "rest" {
  base_url = "https://myaccount.blob.core.windows.net"
  security = {
    http = {
      token = {
        token = var.storage_access_token
      }
    }
  }
}

module "blob" {
  source = "./modules/azure/storage_account_blob"

  account_name   = "myaccount"
  container_name = "mycontainer"
  blob_name      = "config/settings.json"
  content_type   = "application/json"
  content        = jsonencode({ environment = "production" })
}
```

## Example usage (via root module)

```yaml
# configurations/storage_account_blobs.yaml
azure_storage_account_blobs:
  app_config:
    account_name:   myaccount
    container_name: app-configs
    blob_name:      production/config.json
    content_type:   application/json
    content:        '{"env":"production"}'
    access_tier:    Hot
```

```bash
# Apply with storage.azure.com token
export TF_VAR_storage_access_token=$(az account get-access-token \
  --resource https://storage.azure.com --query accessToken -o tsv)
export TF_VAR_storage_account_name=myaccount

terraform apply \
  -var config_file=configurations/storage_account_blobs.yaml
```
