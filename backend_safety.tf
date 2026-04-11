# ── Backend Safety Guard ──────────────────────────────────────────────────────
# The terraform_backend YAML section is READ-ONLY metadata. The resources it
# references (resource group, storage account) must NEVER be managed by the
# same configuration — destroying that config would delete the state storage.
#
# This file enforces that invariant with a terraform_data precondition that
# produces a hard error at plan time if any managed resource overlaps with
# the backend infrastructure.

locals {
  _backend_rg_conflicts = local._terraform_backend != null && try(local._terraform_backend.resource_group_name, "") != "" ? [
    for k, v in merge(try(local._yaml_raw.azure_resource_groups, {}), var.azure_resource_groups) :
    k if try(v.resource_group_name, k) == local._terraform_backend.resource_group_name
  ] : []

  _backend_sa_conflicts = local._terraform_backend != null ? [
    for k, v in merge(try(local._yaml_raw.azure_storage_accounts, {}), var.azure_storage_accounts) :
    k if try(v.account_name, "") == try(local._terraform_backend.storage_account_name, "")
  ] : []
}

resource "terraform_data" "backend_safety" {
  count = local._terraform_backend != null ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(local._backend_rg_conflicts) == 0
      error_message = <<-EOT
        SAFETY: This configuration defines azure_resource_groups that match
        terraform_backend.resource_group_name ('${try(local._terraform_backend.resource_group_name, "")}').

        Conflicting keys: ${join(", ", local._backend_rg_conflicts)}

        The terraform_backend section is read-only metadata — the resources it
        references must never be managed by the same configuration. Destroying
        this config would delete the resource group that holds all Terraform state.

        Fix: move backend resources to a dedicated bootstrap config (00-bootstrap)
        that uses type: local.
      EOT
    }

    precondition {
      condition     = length(local._backend_sa_conflicts) == 0
      error_message = <<-EOT
        SAFETY: This configuration defines azure_storage_accounts that match
        terraform_backend.storage_account_name ('${try(local._terraform_backend.storage_account_name, "")}').

        Conflicting keys: ${join(", ", local._backend_sa_conflicts)}

        The terraform_backend section is read-only metadata — the resources it
        references must never be managed by the same configuration. Destroying
        this config would delete all Terraform state files.

        Fix: move backend resources to a dedicated bootstrap config (00-bootstrap)
        that uses type: local.
      EOT
    }
  }
}
