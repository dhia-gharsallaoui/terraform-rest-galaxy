---
description: Set up or migrate Terraform state boundaries — reads terraform_backend from a YAML config and runs init/plan/apply with the right -backend-config flags. Also supports `bootstrap` and `status`.
argument-hint: <YAML config file | bootstrap | status>
---

Read and follow `.github/prompts/tfstate-boundary.prompt.md` exactly. Treat the argument below as `$input`.

$input = $ARGUMENTS

SAFETY: `terraform_backend` is read-only metadata. The backend resource group and storage account must NEVER be managed by the same configuration that uses them. Bootstrap (00-bootstrap) must always use `type: local`.
