# ── TLS Private Keys ─────────────────────────────────────────────────────────
# Declarative TLS key pair generation. Non-sensitive outputs (public key)
# are added to the context chain for ref: resolution. Sensitive outputs
# (private key PEM) are kept out of the context and injected directly
# where needed (e.g. helm_releases via _tls_key_refs).

variable "tls_private_keys" {
  type = map(object({
    algorithm   = optional(string, "RSA")
    rsa_bits    = optional(number, 4096)
    ecdsa_curve = optional(string, null)
  }))
  description = <<-EOT
    Map of TLS private keys to generate.

    Example:
      tls_private_keys = {
        arc_platform = {
          algorithm = "RSA"
          rsa_bits  = 4096
        }
      }
  EOT
  default     = {}
}

locals {
  tls_private_keys = provider::rest::resolve_map(
    local._ctx_l0,
    merge(try(local._yaml_raw.tls_private_keys, {}), var.tls_private_keys)
  )

  # Context with non-sensitive outputs only.
  # Sensitive private_key_pem is deliberately excluded to avoid tainting
  # the context chain (which would break for_each on downstream resources).
  _tls_ctx = {
    for k, v in local.tls_private_keys : k => merge(v, {
      public_key_pem = tls_private_key.this[k].public_key_pem
      # OpenSSH format: "ssh-rsa AAAA... comment" — ready for authorized_keys and
      # Azure SFTP local user ssh_authorized_keys[*].key fields.
      public_key_openssh = tls_private_key.this[k].public_key_openssh
      # Azure HIS expects PKCS#1 RSA public key (DER SEQUENCE of [n, e]) in base64,
      # matching the az connectedk8s connect CLI format.
      # tls_private_key.public_key_pem is SubjectPublicKeyInfo (PKCS#8) which wraps
      # the PKCS#1 key with a 24-byte ASN.1 header (= 32 base64 chars).
      # Strip PEM armor → strip the 32-char PKCS#8 header → PKCS#1 base64.
      public_key_base64 = substr(
        replace(replace(replace(
          tls_private_key.this[k].public_key_pem, "\n", ""),
          "-----BEGIN PUBLIC KEY-----", ""),
        "-----END PUBLIC KEY-----", ""),
      32, -1)
    })
  }
}

resource "tls_private_key" "this" {
  for_each    = local.tls_private_keys
  algorithm   = each.value.algorithm
  rsa_bits    = try(each.value.rsa_bits, 4096)
  ecdsa_curve = try(each.value.ecdsa_curve, null)
}
