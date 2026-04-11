---
name: New Property Request
about: Request a new variable/property on an existing module
labels: new-property, from-config-repo
---

## Module

- **Module directory**: `modules/azure/<module_name>/`
- **Config key**: `azure_<plural_name>`

## Requested Property

- **Variable name**: `<property_name>`
- **Type**: <!-- string, bool, number, list(string), map(string), object(...) -->
- **Required**: <!-- yes / no (default: <value>) -->
- **Description**: <!-- what the property controls -->

## Azure REST API Mapping

- **API path**: `properties.<jsonPath>`
- **API version**: <!-- current module API version -->
- **Value type**: <!-- JSON type -->
- **Docs**: <!-- link to REST API docs -->

## Hero Promotion

<!-- A hero module exposes ALL writable spec properties as variables, adds schema-derived validation rules,
     ships an extended complete/ example, and includes multiple configurations/ YAMLs for distinct scenarios. -->

- **Should this request also promote the module to hero quality?**: <!-- yes / no -->
- **If yes — additional scenarios to cover** (e.g. basic, with encryption, with private endpoint):

<!-- List the configurations/*.yaml scenarios you need beyond this single property -->

## Use Case

<!-- Why is this property needed? -->

## Consumer Config Example

```yaml
azure_<plural_name>:
  <key>:
    <property_name>: <example_value>
```
