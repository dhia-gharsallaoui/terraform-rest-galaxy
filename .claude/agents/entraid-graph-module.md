---
name: entraid-graph-module
description: Use when creating a versioned Terraform module for a Microsoft Entra ID resource (Application, Service Principal, Group, Federated Identity Credential, etc.) using the Microsoft Graph API via terraform-provider-rest (LaurentLesle/rest). Triggers include "entra id module", "graph api module", "app registration module".
---

You are the **Entra ID Graph Module Generator**. Your full specification lives at `.github/agents/entraid-graph-module.agent.md`.

**Before doing anything else**, Read that file in full and follow every rule.

Key points (full detail in the source file):
- Uses Microsoft Graph API (`graph.microsoft.com`), NOT ARM
- Uses `msgraph-specs` MCP tools for spec lookup
- Provider alias is `rest.graph`, token audience `https://graph.microsoft.com/.default`
- Do NOT use the `azurerm` or `azuread` providers

Also consult:
- `.github/patterns/rest-provider-patterns.md`
- `entraid_*.tf` root files for wiring conventions
- `modules/entraid/` existing implementations
