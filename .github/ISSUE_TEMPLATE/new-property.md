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

## Use Case

<!-- Why is this property needed? -->

## Consumer Config Example

```yaml
azure_<plural_name>:
  <key>:
    <property_name>: <example_value>
```
