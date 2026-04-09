---
description: Discover existing Azure resources via Resource Graph, generate Terraform config + import blocks, and verify with plan. Goal is a clean "No changes" plan.
argument-hint: <scope — resource type, RG name, tag filter, or subscription>
---

Invoke the `tf-import` skill with argument: $ARGUMENTS

Follow `.github/skills/tf-import/SKILL.md` exactly. Observe the safety constraints: NEVER run `terraform destroy`, NEVER run `terraform apply` without `-refresh-only` unless explicitly requested. The target is `terraform plan` showing no changes.
