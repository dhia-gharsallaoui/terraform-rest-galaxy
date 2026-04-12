# ── Validate external references via live API calls ──────────────────────────
# Emits native Terraform warnings for API issues (404, permission errors).
# Set fail_on_warning = true on the provider to fail the plan on warnings.
data "rest_validate_externals" "this" {
  externals       = merge(try(local._yaml_raw.externals, {}), var.externals)
  schema_registry = yamldecode(file("${path.module}/externals_schema.yaml"))
}
