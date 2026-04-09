---
description: Scaffold a versioned Terraform module for an Azure resource, or implement an end-to-end multi-resource scenario, using terraform-provider-rest and the Azure REST API spec.
argument-hint: <resource type | scenario description>
---

Invoke the `tf-module` skill with argument: $ARGUMENTS

Follow `.github/skills/tf-module/SKILL.md` exactly. For single-resource mode, dispatch the `azure-rest-module` subagent. For end-to-end scenarios, plan the multi-resource configuration under `configurations/` before touching modules.
