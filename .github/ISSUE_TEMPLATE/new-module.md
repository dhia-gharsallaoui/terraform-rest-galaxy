---
name: New Module Request
about: Request a new Terraform module for an Azure resource type
labels: new-module, from-config-repo
---

## Resource Type

- **Azure resource provider**: `Microsoft.<Provider>/<ResourceType>`
- **Proposed config key**: `azure_<plural_name>`
- **Proposed module directory**: `modules/azure/<singular_name>/`

## Use Case

<!-- Describe your use case and why this module is needed -->

## Requested Properties

<!-- List the variable names needed in the initial version -->

| Property | Type | Required | Description |
|----------|------|----------|-------------|
|          |      |          |             |

## Azure REST API Reference

- **API version**: <!-- e.g. 2024-01-01 -->
- **Docs**: <!-- link to learn.microsoft.com REST API docs -->

## Hero Module

<!-- A hero module exposes ALL writable spec properties as variables, adds schema-derived validation rules,
     ships an extended complete/ example, and includes multiple configurations/ YAMLs for distinct scenarios.
     It is listed in the Hero Modules table in README.md. -->

- **Should this be a hero module?**: <!-- yes / no -->
- **If yes — key scenarios to cover** (e.g. basic, with encryption, with private endpoint):

<!-- List the configurations/*.yaml scenarios you need -->

## Consumer Config Example

```yaml
azure_<plural_name>:
  <key>:
    resource_group_name: ref:azure_resource_groups.<rg_key>.resource_group_name
    location: ref:azure_resource_groups.<rg_key>.location
    tags: ref:azure_resource_groups.<rg_key>.tags
```
