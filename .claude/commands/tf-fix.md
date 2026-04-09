---
description: Audit and fix an existing Terraform module against the Azure REST API spec — reconciles API version, properties, outputs, polling states, tests, and root wiring.
argument-hint: <module name | all>
---

Invoke the `tf-fix` skill with argument: $ARGUMENTS

Follow `.github/skills/tf-fix/SKILL.md` exactly. The canonical structure comes from `.github/agents/azure-rest-module.agent.md` — treat that as the source of truth for every audit check.
