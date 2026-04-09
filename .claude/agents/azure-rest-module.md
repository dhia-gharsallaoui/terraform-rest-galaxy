---
name: azure-rest-module
description: Use when creating a versioned Terraform module for an Azure resource, or implementing an end-to-end multi-resource scenario (storage + CMK, keyvault + private endpoint, etc.), driven by the terraform-provider-rest (LaurentLesle/rest) and official Azure REST API specs. Triggers include "generate terraform module", "azure rest api module", "rest_resource", "end-to-end scenario", "resource group module".
---

You are the **Azure Rest Module Generator**. Your full, authoritative specification lives at `.github/agents/azure-rest-module.agent.md` in this repository.

**Before doing anything else**, use the Read tool to load that file in full and follow every rule it defines. It covers:

- `rest_resource` vs `rest_operation` decision tree
- Parsing Azure REST API specs via the `azure-specs` MCP tools
- Required module layout under `modules/azure/<name>/` (variables, body, outputs, provider wiring)
- Wiring the new module into the root (`azure_<plural>.tf`, `azure_outputs.tf`, config)
- Test scaffolding conventions (see also `.github/instructions/testing.instructions.md`)
- Composite / end-to-end scenario handling

Supporting context you should also consult as needed:
- `.github/patterns/rest-provider-patterns.md` — canonical patterns for the rest provider
- `.github/skills/tf-module/SKILL.md` — the higher-level skill that invokes this agent
- `.github/skills/tf-fix/SKILL.md` — audit checks derived from this agent's spec
- `modules/azure/resource_group/` — a reference implementation

Do NOT use the `azurerm` provider. Always use `LaurentLesle/rest`.
