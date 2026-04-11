# Source: azure-rest-api-specs
#   spec_path  : storage/data-plane/Microsoft.BlobStorage
#   api_version: 2026-06-06
#   operation  : BlockBlob_Upload  (PUT /{containerName}/{blob}?BlockBlob, synchronous)
#   read       : Blob_GetProperties (HEAD /{containerName}/{blob}, synchronous)
#   delete     : Blob_Delete        (DELETE /{containerName}/{blob}, synchronous)
#
# Architecture note — DATA-PLANE vs ARM:
#   This module targets the Blob Storage data-plane endpoint:
#     https://{accountName}.blob.core.windows.net
#   rather than the ARM endpoint (https://management.azure.com).
#   The provider "rest" must be configured with:
#     base_url = "https://${var.account_name}.blob.core.windows.net"
#
#   Auth modes:
#     "token" — Azure AD bearer token (scope: https://storage.azure.com/.default).
#               Configure via provider security block or pass as Authorization header.
#     "sas"   — SAS token appended to the request URL query string.
#
# Limitation:
#   The blob body is sent as a JSON-encoded object {content: "..."}, not as raw
#   bytes. This module is appropriate for structured text/JSON blobs only.
#   For binary blobs, use Azure CLI (az storage blob upload) or the Azure SDK.

locals {
  api_version = "2026-06-06"
  blob_path   = "/${var.container_name}/${var.blob_name}"

  # Required blob creation headers per the BlockBlob_Upload spec.
  # x-ms-blob-type header is mandatory for PUT on /{containerName}/{blob}?BlockBlob.
  blob_headers = merge(
    {
      "x-ms-blob-type"         = var.blob_type
      "x-ms-version"           = local.api_version
      "x-ms-blob-content-type" = var.content_type
    },
    var.access_tier != null ? { "x-ms-access-tier" = var.access_tier } : {},
    # User-defined metadata: x-ms-meta-{key} = {value}
    { for k, v in coalesce(var.metadata, {}) : "x-ms-meta-${k}" => v },
  )

  # SAS query parameters — only applied when auth_mode = "sas".
  # The SAS token string is expanded into individual key=value query parameters.
  # When auth_mode = "token", the provider-level Authorization header is used.
  sas_query = var.auth_mode == "sas" && var.sas_token != null ? {
    for pair in split("&", var.sas_token) :
    split("=", pair)[0] => [join("=", slice(split("=", pair), 1, length(split("=", pair))))]
    if length(split("=", pair)) >= 2
  } : {}

  # Blob body — text/JSON content wrapped in a JSON object for the REST provider.
  # The provider serialises this as a JSON request body. For a null content value,
  # an empty JSON object is sent, which creates a zero-byte blob.
  body = var.content != null ? { content = var.content } : {}
}

resource "rest_resource" "blob" {
  path            = local.blob_path
  create_method   = "PUT"
  check_existance = var.check_existance

  # The data-plane spec uses x-ms-blob-type as the discriminator in the URL path
  # (?BlockBlob suffix). The REST provider appends query parameters to the PUT URL.
  # We include the api-version and any SAS parameters here.
  query = merge(
    { "api-version" = [local.api_version] },
    local.sas_query,
  )

  header = local.blob_headers
  body   = local.body

  output_attrs = toset([
    "ETag",
    "Last-Modified",
    "x-ms-version-id",
    "x-ms-request-server-encrypted",
    "x-ms-blob-type",
    "Content-Type",
    "x-ms-access-tier",
  ])

  # BlockBlob upload is synchronous — PUT returns 201 when the blob is written.
  # No poll_create needed.

  # DELETE returns 202 for soft-deleted blobs; poll until 404 (resource gone).
  # For accounts without soft-delete, DELETE is synchronous (204).
  # The poll handles both cases: 404 is success, 200/202 are pending.
  poll_delete = {
    status_locator    = "code"
    default_delay_sec = 5
    status = {
      success = "404"
      pending = ["200", "202"]
    }
  }
}
