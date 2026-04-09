# Restful Provider Patterns & Learnings

Accumulated patterns and hard-won lessons from working with `LaurentLesle/rest ~> 1.0` against Azure ARM APIs. Referenced by `tf-import`, `tf-module`, `tf-fix`, and the Azure Rest Module Generator agent.

---

## 1. Import Body Specificity

### Problem

When importing a `rest_resource`, the `body` in the import block determines the **type** of the state body. Using `properties = null` imports the entire ARM GET response — including all read-only fields (`provisioningState`, `resourceGuid`, `etag`, nested `id`/`type` on sub-resources, etc.) — into the state body type.

This causes perpetual one-time drift on every plan: Terraform sees the read-only fields in state but not in the HCL body, and shows them as removals.

### Root Cause

The rest provider's `dynamic.FromJSON(GET_response, state.Body.Type)` filters the GET response through the state body type. If the state body type is broad (because `properties = null` made it accept everything), all read-only fields pass through.

### Solution

**Always list only writable properties explicitly in import body blocks.** Derive the writable property list from the module's `body` local in `main.tf`.

```hcl
# ❌ BAD — imports ALL properties including read-only ones
body = {
  location   = null
  properties = null
  tags       = null
}

# ✅ GOOD — imports ONLY writable properties
body = {
  location = null
  properties = {
    addressSpace = null
    dhcpOptions  = null
    subnets      = null
  }
  tags = null
}
```

### How to Derive the Writable Properties

1. Read `modules/azure/<resource_name>/main.tf`
2. Find the `local.body` or `local.properties` definition
3. List every property key that appears (conditionally or unconditionally) in the `merge()` — these are writable
4. Use these as the property list in the import `body`, all set to `null`
5. For nested objects (like `sku`), use `sku = null` if the whole object is writable
6. For `properties`, always expand to list individual writable sub-properties

### One-Time Normalization Pattern

Even with specific import bodies, some drift is expected on the **first** plan after import:
- **Nested arrays** (routes, subnets, ipConfigurations) contain read-only sub-properties (`etag`, `id`, `type`, `provisioningState`) inside each array item that the import body cannot exclude at the item level
- **Top-level read-only fields** (`etag`, `id`, `name`, `type`) from the ARM response envelope

This is a one-time normalization. After the first `terraform apply`, the state body type resets to match the HCL body type, and subsequent plans show **0 changes**.

**Expected one-time plan pattern:** `N to import, 0 to add, M to change, 0 to destroy` — where M ≤ N (only imported resources change, never destroy).

---

## 2. `output_attrs` — Controlling Output State Size

### Problem

By default, `rest_resource` stores the **entire** ARM GET response in `.output`. For complex resources (firewalls, virtual network gateways, load balancers), this can include hundreds of read-only fields, deeply nested arrays, and metadata that bloats the state file and causes unnecessary output drift.

### Solution

Add `output_attrs` to every `rest_resource` to whitelist only the output fields needed by module outputs:

```hcl
resource "rest_resource" "virtual_network" {
  # ...
  body = local.body

  output_attrs = toset([
    "properties.provisioningState",
  ])

  # ...
}
```

### How to Determine output_attrs

1. Read `modules/azure/<resource_name>/outputs.tf`
2. Find every output that reads from `rest_resource.<name>.output.<path>`
3. Convert those paths to gjson paths for `output_attrs`
4. Always include `properties.provisioningState` (used for polling and status reporting)

### Common output_attrs by Resource Type

| Resource Type | Typical output_attrs |
|---|---|
| resource_group | `properties.provisioningState`, `type`, `tags` |
| virtual_network | `properties.provisioningState` |
| public_ip_address | `properties.ipAddress`, `properties.provisioningState` |
| route_table | `properties.provisioningState` |
| express_route_circuit | `properties.serviceKey`, `properties.provisioningState`, `properties.serviceProviderProvisioningState` |
| virtual_network_gateway | `properties.provisioningState`, `properties.bgpSettings` |
| virtual_network_gateway_connection | `properties.provisioningState`, `properties.connectionStatus` |
| load_balancer | `properties.provisioningState`, `properties.frontendIPConfigurations`, `properties.backendAddressPools` |
| network_interface | `properties.provisioningState`, `properties.macAddress`, `properties.ipConfigurations` |
| private_endpoint | `properties.provisioningState`, `properties.networkInterfaces`, `properties.customDnsConfigs` |
| firewall_policy | `properties.provisioningState` |
| azure_firewall | `properties.provisioningState`, `properties.ipConfigurations`, `properties.hubIPAddresses`, `properties.sku`, `properties.firewallPolicy`, `properties.threatIntelMode` |

---

## 3. `write_only_attrs` — When It Does NOT Help

### Problem (attempted solution that failed)

During import drift investigation, `write_only_attrs` was tested as a way to exclude read-only fields from the GET response. This **does not work** for our use case.

### Root Cause

The rest provider's `write_only_attrs` has this condition in source code:
```go
if !gjson.Get(getResponse, path).Exists() {
    // use the value from state instead of GET
}
```

It compensates for attributes that are **MISSING from the GET response** (e.g., secrets, passwords). Our problem is the opposite: attributes that are **PRESENT in the GET response** that we don't want. Since the read-only fields ARE returned by ARM GET, `write_only_attrs` never triggers.

### When to Actually Use write_only_attrs

Only for true write-only attributes where:
- The property is sent in PUT but **not returned** in GET
- Examples: passwords, secrets, connection strings that ARM redacts from responses

---

## 4. Output Access Pattern — Direct vs jsondecode

### Problem

Some modules were generated with `jsondecode(rest_resource.xxx.output)` to access output fields. This is incorrect — the `.output` attribute is already a dynamic object, not a JSON string.

### Solution

Always use direct attribute access:

```hcl
# ❌ BAD — unnecessary jsondecode
output "provisioning_state" {
  value = try(jsondecode(rest_resource.virtual_network_gateway_connection.output).properties.provisioningState, null)
}

# ✅ GOOD — direct attribute access
output "provisioning_state" {
  value = try(rest_resource.virtual_network_gateway_connection.output.properties.provisioningState, null)
}
```

---

## 5. Plan-Time Known Outputs

### Problem

If a module output reads from `rest_resource.*.output.id`, the value is `(known after apply)`. This prevents downstream modules from computing resource paths at plan time.

### Solution

For any output that can be deterministically derived from input variables, echo the input:

```hcl
# ✅ Plan-time known — echoes computed local
output "id" {
  value = local.kv_path  # built from var.subscription_id + var.resource_group_name + var.vault_name
}

output "name" {
  value = var.vault_name
}

# Only truly Azure-assigned values use rest output
output "provisioning_state" {
  value = try(rest_resource.key_vault.output.properties.provisioningState, null)
}
```

This pattern is critical for `ref:` resolution in `azure_config.tf` — downstream modules need `id` and `name` at plan time to construct their own resource paths.

---

## 6. ARM Body Defaults for Writable Collection Properties

### Problem

Some ARM resources have collection properties (arrays) that are writable and returned by GET with default empty values. If the module's HCL body doesn't include them, the GET response includes them but the body type excludes them, causing drift.

### Solution

For resources with writable collection properties that ARM initializes to defaults, include them in the module body with sensible defaults:

```hcl
# Azure Firewall example — ARM returns empty arrays for these
body = merge(
  {
    location = var.location
    properties = merge(
      { /* ... core properties ... */ },
      { additionalProperties       = var.additional_properties },
      { applicationRuleCollections = var.application_rule_collections },
      { natRuleCollections         = var.nat_rule_collections },
      { networkRuleCollections     = var.network_rule_collections },
    )
  },
  var.tags != null ? { tags = var.tags } : {},
)
```

With corresponding variables defaulting to empty:
```hcl
variable "application_rule_collections" {
  type    = list(any)
  default = []
}
```

This ensures the HCL body type includes these properties, and the `dynamic.FromJSON` filter keeps them aligned.

---

## 7. Dependency Layer Ordering with depends_on

### Problem

When sub-module outputs echo input variables (plan-time known), Terraform cannot infer cross-module dependencies from data flow. Resources may race and fail with 404s.

### Solution

Every module block in the root must include `depends_on` referencing modules from the previous layer:

```hcl
# Layer 0 — no depends_on
module "azure_resource_groups" { ... }

# Layer 1 — depends on Layer 0
module "azure_virtual_networks" {
  depends_on = [module.azure_resource_groups]
  ...
}

# Layer 2 — depends on Layer 1
module "azure_virtual_network_gateways" {
  depends_on = [module.azure_virtual_networks, module.azure_public_ip_addresses]
  ...
}
```

---

## 8. Import Block Layer Ordering

### Problem

Import blocks are processed in parallel by default. Resources with cross-dependencies should be grouped and commented by layer for clarity.

### Solution

Organize import blocks in the same layer order as `azure_config.tf`:

```hcl
# ── Layer 0b: azure_resource_groups ─────────────────────────
import { to = module.azure_resource_groups["..."] ... }

# ── Layer 1: azure_virtual_networks, azure_public_ip_addresses ────
import { to = module.azure_virtual_networks["..."] ... }
import { to = module.azure_public_ip_addresses["..."] ... }

# ── Layer 2: azure_virtual_network_gateways, azure_load_balancers ─
import { to = module.azure_virtual_network_gateways["..."] ... }

# ── Layer 3: azure_firewalls, azure_virtual_network_gateway_connections ─────────────
import { to = module.azure_firewalls["..."] ... }
import { to = module.azure_virtual_network_gateway_connections["..."] ... }
```

---

## 9. Proof Pattern — Verifying Zero Drift

After the first `terraform apply` that imports and normalizes state, always verify:

```bash
terraform plan -var config_file=configurations/<name>.yaml
```

**Expected**: `No changes. Your infrastructure matches the configuration.`

Resources that were previously imported AND applied (e.g., `azure_resource_groups`, `azure_firewall_policies`) serve as proof that the type-based filtering works. They show zero drift on subsequent plans, confirming the pattern.

---

## 10. Common ARM Read-Only Properties by Resource Type

These properties are returned by ARM GET but must NOT be in the module body or import body properties:

| Always Read-Only | Found In |
|---|---|
| `provisioningState` | Every resource's `properties` |
| `resourceGuid` | Most networking resources |
| `etag` | Most resources (top-level and nested) |
| `id` | Nested sub-resources (subnets, routes, ipConfigurations) |
| `type` | Nested sub-resources |
| `name` | Top-level (ARM envelope field, not in `properties`) |

| Resource-Specific Read-Only | Resource Type |
|---|---|
| `ipAddress`, `ipConfiguration` | public_ip_address |
| `macAddress`, `privateEndpoint`, `hostedWorkloads` | network_interface |
| `networkInterfaces`, `customDnsConfigs` | private_endpoint |
| `serviceKey`, `circuitProvisioningState`, `peerings` | express_route_circuit |
| `connectionStatus`, `egressBytesTransferred`, `tunnelProperties` | virtual_network_gateway_connection |
| `sku.capacity`, `natRules`, `virtualNetworkGatewayPolicyGroups` | virtual_network_gateway |
| `inboundNatPools`, `outboundRules` | load_balancer |
| `virtualNetworkPeerings`, `flowLogs` | virtual_network |
| `subnets` (in route_table) | route_table |

---

## 11. Entra ID Replication Polling (`poll_create` for Graph API modules)

### Problem

When Terraform creates an Entra ID object (group, user, application, service principal) via Microsoft Graph POST and then immediately creates an Azure ARM resource referencing that object (e.g., a role assignment with `principalId`), ARM returns `PrincipalNotFound (400)`.

This happens even though the Graph POST returned `201 Created` successfully. The newly-created Entra ID object has not yet replicated to the ARM directory cache.

### Root Cause

Azure ARM maintains a **negative cache** for directory principal lookups. When ARM attempts to resolve a `principalId` for a role assignment and the principal does not yet exist in ARM's directory view, ARM caches the "not found" result. This negative-cache TTL is approximately **30 seconds**.

Even after the Entra ID object becomes globally readable in Graph, ARM continues to serve the cached "not found" until the TTL expires. This is a cross-service eventual consistency issue between Microsoft Graph and Azure Resource Manager.

### Solution

Every Entra ID module MUST include a `poll_create` block that polls the read path (GET) after creation. This uses the rest provider's native polling mechanism to wait until the object is confirmed readable before Terraform proceeds to dependent resources.

```hcl
resource "rest_resource" "group" {
  path          = "/v1.0/groups"
  create_method = "POST"
  # ...

  poll_create = {
    status_locator    = "code"       # Poll using HTTP status code
    default_delay_sec = 30           # Wait 30s — matches ARM negative-cache TTL
    status = {
      success = "200"                # GET /v1.0/groups/{id} returns 200 = replicated
      pending = ["404"]              # GET returns 404 = still propagating
    }
  }
}
```

### Design Decisions

| Decision | Rationale |
|---|---|
| `status_locator = "code"` | Graph GET returns HTTP 200 on success and 404 when the object hasn't replicated. There is no `provisioningState` body field for Graph objects. |
| `default_delay_sec = 30` | ARM negative-cache TTL for directory lookups is ~30 seconds. This ensures that when the provider proceeds, ARM's cache has expired and will fetch the now-replicated object. |
| Applied to ALL Entra ID modules | Any Entra ID object can be referenced by ARM resources (role assignments, Key Vault access policies, etc.). The poll cost is minimal (one extra GET after creation) and prevents intermittent `PrincipalNotFound` failures. |
| `poll_create` over `time_sleep` | `poll_create` is provider-native, tied to actual object readability, and does not require the `hashicorp/time` provider. `time_sleep` is a blunt delay disconnected from the resource lifecycle. |

### Which Modules Need This

Every module under `modules/entraid/` must include the `poll_create` block:

| Module | Read path polled |
|---|---|
| `entraid/application` | `/v1.0/applications/{id}` |
| `entraid/group` | `/v1.0/groups/{id}` |
| `entraid/user` | `/v1.0/users/{id}` |
| `entraid/group_member` | `/v1.0/directoryObjects/{member_id}` |
| `entraid/service_principal` | `/v1.0/servicePrincipals/{id}` |

### What NOT to Use

- **`time_sleep`** (`hashicorp/time`) — adds an external provider dependency and uses an arbitrary delay not tied to actual readability.
- **`precheck_create`** on the ARM role assignment — the role assignment uses the ARM provider (`rest` default), which cannot poll Graph endpoints. The fix belongs on the Entra ID module side.

---

## 8. External References (`externals`) — Schema-Driven Validation

### Problem

Some resources referenced in configurations are **not managed by Terraform** — e.g. a workforce Entra ID tenant created manually, an existing GitHub organization, a legacy resource group, or an ExpressRoute port managed by another team. These cannot use `rest_resource` or `rest_operation` modules, but other managed resources need to reference their attributes (tenant ID, domain, resource group name, etc.) via `ref:` expressions.

### Solution

Use the `externals` top-level key in the configuration YAML (or the `var.externals` HCL variable) to declare static attribute maps for unmanaged resources. The externals map is injected into the `ref:` resolution context at **Layer 0** — before subscriptions, resource groups, or any other resource — making it available to every managed resource at every layer.

Validation is **schema-driven** via `provider::rest::validate_externals()`. Schemas are resolved in this order:
1. **Schema registry file** (`externals_schema.yaml`) — a centralized mapping of category names to their API schemas, maintained alongside module creation
2. **Inline `_schema`** — a fallback for ad-hoc categories not yet in the registry

### Schema registry file (`externals_schema.yaml`)

A centralized YAML file at the root of the Terraform workspace that maps category names to their validation schemas. This file **grows alongside module creation** — each new module adds its entry.

```yaml
# externals_schema.yaml
tenants:
  api: arm
  path: "/tenants"
  api_version: "2022-12-01"
  search_filter: "tenantId eq '{tenant_id}'"
  operation: GET (list + filter)

azure_resource_groups:
  api: arm
  path: "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}"
  api_version: "2025-04-01"
  operation: GET

azure_storage_accounts:
  api: arm
  path: "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Storage/storageAccounts/{account_name}"
  api_version: "2025-08-01"
  operation: GET

entraid_groups:
  api: graph
  path: "/v1.0/groups/{id}"
  operation: GET

github_organizations:
  api: github
  path: "/orgs/{org_name}"
  operation: GET
```

The registry is loaded in `azure_layers.tf`:

```hcl
_externals_schema = yamldecode(file("${path.module}/externals_schema.yaml"))
_externals = provider::rest::validate_externals(local._externals_raw, local._externals_schema)
```

### YAML Syntax (config files)

With the registry, config YAML stays clean — no inline `_schema` needed:

```yaml
externals:
  tenants:
    corp:
      tenant_id: "4fcc1d67-2ccc-4e50-99c7-93a41aecbca3"
      domain: "contoso.onmicrosoft.com"
      location: Europe

  azure_resource_groups:
    shared_networking:
      resource_group_name: rg-shared-network
      location: westeurope
      subscription_id: "00000000-0000-0000-0000-000000000000"
```

For ad-hoc categories not in the registry, the inline `_schema` fallback still works:

```yaml
externals:
  custom_category:
    _schema:
      api: arm
      path: "/subscriptions/{subscription_id}/providers/Microsoft.New/things/{name}"
      api_version: "2025-01-01"
    my_thing:
      subscription_id: "..."
      name: "my-thing"
```

### _schema field reference

| Field | Required | Description |
|---|---|---|
| `api` | Yes | Which API to call: `arm` (Azure RM), `graph` (Microsoft Graph), `github` (GitHub API) |
| `path` | Yes | URL path template. `{attr_name}` placeholders are substituted from entry attributes |
| `api_version` | No | Appended as `?api-version=` query param (ARM convention) |
| `search_filter` | No | OData `$filter` template with `{attr_name}` placeholders. Used for list endpoints |

### Examples

Minimal config YAML (schemas resolved from `externals_schema.yaml` registry):

```yaml
externals:
  tenants:
    corp:
      tenant_id: "4fcc1d67-2ccc-4e50-99c7-93a41aecbca3"
      domain: "contoso.onmicrosoft.com"
      location: Europe

  azure_resource_groups:
    shared_networking:
      resource_group_name: rg-shared-network
      location: westeurope
      subscription_id: "00000000-0000-0000-0000-000000000000"

  github_organizations:
    platform:
      org_name: contoso-platform

  entraid_groups:
    admins:
      id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      display_name: "Platform Admins"

  # Category not in registry and no inline _schema → passed through without validation
  custom_data:
    notes:
      purpose: "just static key-value data"
```

### How validation works

1. `provider::rest::validate_externals(externals, schema_registry)` walks each category
2. **Schema lookup**: checks `schema_registry` (from `externals_schema.yaml`) first, then falls back to inline `_schema` key
3. If no schema is found, the category passes through without validation
4. For each entry, substitutes `{attr_name}` placeholders from entry attributes into the path/filter templates
5. Makes a read-only GET to the resolved URL using the appropriate token from the provider config
6. **HTTP 200** → resource exists, validation passes
7. **HTTP 404** → resource not found, raises a Terraform error
8. **HTTP 401/403** → token invalid or placeholder, silently skips (graceful degradation for tests)
9. **No token configured** → skips validation for that API

### Provider configuration

```hcl
provider "rest" {
  arm_token   = var.access_token        # Azure management.azure.com token
  graph_token = var.graph_access_token   # Microsoft Graph token (optional)
  github_token = var.github_token        # GitHub PAT (optional)
}
```

### Referencing externals

```yaml
azure_ciam_directories:
  customer_portal:
    location: ref:externals.tenants.corp.location
    # ...

azure_virtual_networks:
  spoke:
    resource_group_name: ref:externals.azure_resource_groups.shared_networking.resource_group_name
    location: ref:externals.azure_resource_groups.shared_networking.location
    # ...
```

### Resolution path

`ref:externals.tenants.corp.tenant_id` resolves as:

```
context["externals"]["tenants"]["corp"]["tenant_id"]
  → "4fcc1d67-2ccc-4e50-99c7-93a41aecbca3"
```

### HCL variable alternative

```hcl
variable "externals" {
  default = {
    tenants = {
      corp = {
        tenant_id = "4fcc1d67-2ccc-4e50-99c7-93a41aecbca3"
        domain    = "contoso.onmicrosoft.com"
      }
    }
  }
}
```

YAML and HCL sources are merged (HCL overrides on key collision).

### Adding a new externals category

When creating a new Terraform module, add its entry to `externals_schema.yaml`:

```yaml
# Added when creating modules/azure/my_new_resource/
azure_my_new_resources:
  api: arm
  path: "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Foo/bars/{name}"
  api_version: "2025-01-01"
  operation: GET
```

No provider code changes needed — the schema registry is pure data.

### When to use `externals` vs `remote_states`

| Feature | `externals` | `remote_states` |
|---|---|---|
| Data source | Static values (YAML or HCL variable) | Live Terraform remote state outputs |
| Use case | Resources not in any Terraform state | Resources managed by another Terraform workspace |
| Freshness | Manual — update YAML when values change | Automatic — reads latest state on every plan |
| Validation | Schema-driven via `_schema` + `validate_externals` | None (trusts remote state) |
| ref: prefix | `ref:externals.<category>.<key>.<attr>` | `ref:remote_states.<name>.<path>` |

---

## 12. Name Availability Pre-Check for Globally Unique Resources

### Problem

Azure resources with globally unique names (storage accounts, key vaults, CIAM directories) fail at apply time with a cryptic `409 StorageAccountAlreadyTaken` or similar error if the name is already taken by another subscription. This wastes time — the operator may have already waited through resource provider registration, dependency creation, etc.

### Solution

Add a `rest_operation` that calls the ARM `checkNameAvailability` API **before** the resource PUT. Use a `lifecycle.precondition` on the main resource to surface a clear error message.

```hcl
# ── Name availability pre-check ──────────────────────────────────────────────
resource "rest_operation" "check_name_availability" {
  count  = var.check_existance ? 0 : 1
  path   = "/subscriptions/${var.subscription_id}/providers/Microsoft.Storage/checkNameAvailability"
  method = "POST"

  query = {
    api-version = [local.api_version]
  }

  body = {
    name = var.account_name
    type = "Microsoft.Storage/storageAccounts"
  }

  output_attrs = toset(["nameAvailable", "reason", "message"])
}

resource "rest_resource" "storage_account" {
  # ... all existing config ...

  lifecycle {
    precondition {
      condition     = var.check_existance || rest_operation.check_name_availability[0].output.nameAvailable
      error_message = "Storage account name '${var.account_name}' is not available: ${try(rest_operation.check_name_availability[0].output.message, "unknown reason")}. Choose a different account_name."
    }
  }

  # ... poll_create, poll_update, etc.
}
```

### When to add this pattern

Add a `checkNameAvailability` pre-check whenever **all** of these apply:

1. The resource name is **globally unique** across Azure (not just within a resource group)
2. The ARM spec includes a `checkNameAvailability` POST operation for the resource provider
3. The check response returns `{nameAvailable, reason, message}`

### Azure resources with checkNameAvailability APIs

| Resource | API path | Request body |
|---|---|---|
| **Storage Account** | `/subscriptions/{id}/providers/Microsoft.Storage/checkNameAvailability` | `{name, type: "Microsoft.Storage/storageAccounts"}` |
| **Key Vault** | `/subscriptions/{id}/providers/Microsoft.KeyVault/checkNameAvailability` | `{name, type: "Microsoft.KeyVault/vaults"}` |
| **CIAM Directory** | `/subscriptions/{id}/providers/Microsoft.AzureActiveDirectory/checkNameAvailability` | `{name, countryCode}` |
| Container Registry | `/subscriptions/{id}/providers/Microsoft.ContainerRegistry/checkNameAvailability` | `{name, type}` |
| Cosmos DB | `/subscriptions/{id}/providers/Microsoft.DocumentDB/databaseAccountNames/{name}` | GET (different pattern) |
| Event Hub | `/subscriptions/{id}/providers/Microsoft.EventHub/checkNameAvailability` | `{name}` |
| Service Bus | `/subscriptions/{id}/providers/Microsoft.ServiceBus/checkNameAvailability` | `{name}` |

When creating a new module for any of these, always include the check.

### Design decisions

| Decision | Rationale |
|---|---|
| `rest_operation` (not `data` source) | `checkNameAvailability` is POST — `data "rest_resource"` only supports GET |
| `count = var.check_existance ? 0 : 1` | Skip when importing (brownfield) — the name IS taken by us |
| `lifecycle.precondition` (not `postcondition`) | Precondition evaluates before the resource is created, preventing the wasted PUT |
| No `try(..., true)` on condition | If the output is unreadable, we want a loud error — not a silent bypass |
| `try()` on `error_message` only | Error message string must not itself fail evaluation |
| Runs at apply time, not plan time | POST operations cannot run during plan. This is an apply-time guard, not a plan-time check. The check fires before the PUT, preventing wasted time on subsequent resources |

### Common mistakes

```hcl
# ❌ BAD — try() defaults to true, silently bypasses the check
condition = var.check_existance || try(rest_operation.check_name_availability[0].output.nameAvailable, true)

# ✅ GOOD — no try() on condition, errors are surfaced
condition = var.check_existance || rest_operation.check_name_availability[0].output.nameAvailable
```

```hcl
# ❌ BAD — output_attrs as plain list (provider may not filter correctly)
output_attrs = ["nameAvailable", "reason", "message"]

# ✅ GOOD — always use toset()
output_attrs = toset(["nameAvailable", "reason", "message"])
```

---

## 13. Permission Pre-Check (`checkAccess`) for Elevated-Permission Resources

### Problem

Some Azure resources require elevated or uncommon permissions (e.g. Billing Account Owner, Subscription Owner). When the caller lacks the required permission, the PUT fails at apply time with a cryptic `403 Forbidden` or `401 Unauthorized` after potentially long waits (LRO polling, dependency creation). The operator gets no actionable guidance about which role to activate or request.

### Solution

Add a `rest_operation` that calls the ARM `checkAccess` API **before** the resource PUT. Use Terraform `check` blocks (advisory warnings) to surface clear, actionable guidance when permissions are missing. The check is **opt-in** via a `var.precheck_access` variable (default `false`) because it adds API calls.

```hcl
# ── variables.tf ──────────────────────────────────────────────────────────────
variable "precheck_access" {
  description = "When true, call checkAccess before creation to verify caller permissions."
  type        = bool
  default     = false
}

# ── main.tf ───────────────────────────────────────────────────────────────────

# ── Pre-check: verify caller has required permissions ────────────────────────
resource "rest_operation" "check_access" {
  count  = var.precheck_access ? 1 : 0
  path   = "<scope>/checkAccess"
  method = "POST"

  query = {
    api-version = [local.api_version]
  }

  body = {
    actions = [
      "<Namespace>/<resourceType>/write",
      "<Namespace>/<resourceType>/delete",
    ]
  }
}

locals {
  _check_access_results = var.precheck_access ? rest_operation.check_access[0].output : null

  _write_allowed = var.precheck_access ? try(
    [for r in local._check_access_results : r if r.action == "<Namespace>/<resourceType>/write"][0].accessDecision == "Allowed",
    false
  ) : true

  _delete_allowed = var.precheck_access ? try(
    [for r in local._check_access_results : r if r.action == "<Namespace>/<resourceType>/delete"][0].accessDecision == "Allowed",
    false
  ) : true
}

# ── Access pre-check assertions (advisory, not blocking) ────────────────────
check "<resource>_write_access" {
  assert {
    condition     = local._write_allowed
    error_message = <<-EOT
      Access denied: the current caller does not have
      '<Namespace>/<resourceType>/write'
      on scope '<scope>'.

      Required role: <RoleName>.
      If you have a PIM eligible assignment, activate it in the Azure portal:
        Portal → <navigation path> → Eligible assignments
    EOT
  }
}

check "<resource>_delete_access" {
  assert {
    condition     = local._delete_allowed
    error_message = <<-EOT
      Warning: the current caller does not have
      '<Namespace>/<resourceType>/delete'
      on scope '<scope>'.

      Terraform destroy will fail. Consider activating your PIM eligible
      <RoleName> role before running destroy.
    EOT
  }
}
```

### When to add this pattern

Add a `checkAccess` pre-check when **any** of these apply:

1. The resource requires **elevated permissions** not commonly held (Billing Account Owner, Subscription Owner, etc.)
2. The resource operates **cross-tenant** (billing associated tenants, lighthouse delegations)
3. The permission is frequently misconfigured or requires **PIM activation**
4. The `checkAccess` POST API is available at the resource scope

### Design decisions

| Decision | Rationale |
|---|---|
| `check` block (not `lifecycle.precondition`) | Permission issues are **advisory** — the caller may have just-in-time access that activates during apply, or the check may produce false negatives in cross-tenant scenarios. `check` warns without blocking. |
| `var.precheck_access` opt-in (default `false`) | Adds POST API calls per resource. Opt-in avoids unnecessary API traffic for callers who know they have permissions. |
| `var.header` for cross-tenant tokens | Billing and cross-tenant resources need `ephemeral_header` to pass tenant-specific tokens. The `checkAccess` call must use the same header. |
| Separate write/delete checks | Write permission is needed for create/update; delete permission only for destroy. Surfacing both independently helps operators activate the right PIM role. |
| `try(..., false)` on access parse | If the response is malformed or the action is not in the result, assume denied — fail safe. |

### Azure resources that benefit from this pattern

| Resource | Scope for checkAccess | Actions to check |
|---|---|---|
| `billing_associated_tenant` | `/providers/Microsoft.Billing/billingAccounts/{name}` | `.../associatedTenants/write`, `.../associatedTenants/delete` |
| `subscription` | `/providers/Microsoft.Billing/billingAccounts/{name}` | `.../billingSubscriptions/write` |
| `role_assignment` | The target `scope` | `Microsoft.Authorization/roleAssignments/write` |
| `management_group` | `/providers/Microsoft.Management/managementGroups/{name}` | `.../write`, `.../delete` |

### Relationship to other pre-checks

| Pre-check | Mechanism | Timing | Blocking? | Pattern |
|---|---|---|---|---|
| Provider registration | `data "rest_resource"` (GET) | Plan time | Yes (`precondition`) | tf-module convention |
| Name availability | `rest_operation` (POST) | Apply time | Yes (`precondition`) | [Pattern #12](#12-name-availability-pre-check-for-globally-unique-resources) |
| Permission check | `rest_operation` (POST) | Apply time | No (`check` — advisory) | This pattern (#13) |

---

## 14. `ephemeral_header` — NOT Available During Delete

### Problem

The rest provider's `ephemeral_header` attribute is a **write-only** attribute (Terraform framework limitation). Write-only attributes are stored only during apply and are NOT passed to the Delete handler. The provider's Delete code explicitly nulls `state.Header` when the ephemeral flag is set in private state:

```go
// resource.go (Delete handler)
if hasEphemeralHeaderFlag(privateState) {
    state.Header = types.MapNull(types.StringType)
}
```

This means any resource using `ephemeral_header` for authentication will attempt to delete **without credentials**, resulting in `401 Unauthorized` or `403 system:anonymous` errors.

### Root Cause

Terraform's framework does not pass write-only attribute values in the `DeleteRequest`. The provider has no access to `ephemeral_header` during the Delete lifecycle. The ephemeral header flag (stored in Terraform's private state) survives, but the actual header values do not.

### Solution

**Use `header` (not `ephemeral_header`) for any resource that needs to be destroyed.** To prevent the token-rotation drift that `ephemeral_header` was meant to solve, pair `header` with token expiry tracking — only regenerate the token when it's near expiration.

```hcl
# ✅ GOOD — header is available during Delete
resource "rest_resource" "namespace" {
  # ...
  header = {
    Authorization = "Bearer ${var.cluster_token}"
  }
}

# ❌ BAD — ephemeral_header is not available during Delete
resource "rest_resource" "namespace" {
  # ...
  ephemeral_header = {
    Authorization = "Bearer ${var.cluster_token}"
  }
}
```

### When `ephemeral_header` IS safe

Only use `ephemeral_header` for resources where deletion is never needed — e.g., `rest_operation` (fire-and-forget, no lifecycle), or resources managed purely via `terraform apply` without destroy.

### Migrating from `ephemeral_header` to `header`

Resources that were previously applied with `ephemeral_header` have the ephemeral flag set in private state. To migrate:

1. Change `ephemeral_header` to `header` in the module
2. Run a targeted `terraform apply` on affected resources (e.g. `terraform apply -target='module.k8s_*'`)
3. This clears the ephemeral flag from private state and stores the header value
4. Destroy now works with the stored header

---

## 15. ARM `poll_delete` — 404 Means Success

### Problem

ARM DELETE for many resources returns `202 Accepted` (async). The provider then polls the resource URL with GET. When the resource is fully deleted, GET returns `404 Not Found`. If `poll_delete` treats `404` as a failure, the destroy hangs or errors out even though the resource is successfully deleted.

### Solution

For async ARM deletes, configure `poll_delete` to treat `404` as **success** (resource gone) and `200`/`202` as **pending** (still deleting):

```hcl
poll_delete = {
  status_locator    = "code"
  default_delay_sec = 5
  status = {
    success = "404"
    pending = ["200", "202"]
  }
}
```

### Common mistake

```hcl
# ❌ BAD — 404 is pending/failure, destroy will error when resource is gone
poll_delete = {
  status_locator    = "code"
  default_delay_sec = 5
  status = {
    success = "200"
    pending = ["202"]
  }
}
```

### Which resources need this

Any ARM resource where DELETE returns `202` and the provider polls the resource URL (not an operation URL). Common examples: Container Registry, Storage Account, Key Vault, Virtual Network Gateway.

For resources that poll via `Azure-AsyncOperation` or `Location` headers instead, the poll target is the operation URL which returns `200` with `provisioningState`, not the resource URL — these do NOT need `404` as success.

---

## 16. Kubernetes Server-Side Mutations — Preventing Body Drift

### Problem

Kubernetes mutates resources server-side after creation. The API server and admission controllers inject fields that are not in the original body. On subsequent Read, these injected fields appear in the GET response but not in the Terraform body, causing perpetual drift.

### Common Server-Side Mutations

| Resource | Injected Field | Description |
|---|---|---|
| **Namespace** | `metadata.labels["kubernetes.io/metadata.name"]` | Auto-added to every namespace, value = namespace name |
| **All resources** | `metadata.managedFields` | Tracks field ownership — excluded by `output_attrs` |
| **All resources** | `metadata.resourceVersion`, `metadata.uid`, `metadata.creationTimestamp` | Server-assigned metadata — excluded by `output_attrs` |
| **ServiceAccount** | `secrets` (pre-K8s 1.24) | Auto-created service account token secret |
| **Deployment** | `spec.template.metadata.labels["pod-template-hash"]` | Added by the ReplicaSet controller, but only to the ReplicaSet — not to the Deployment itself |

### Solution

Include known server-injected fields in the module body so the Terraform state matches the API response:

```hcl
# Namespace example — include the auto-injected label
locals {
  all_labels = merge(
    { "kubernetes.io/metadata.name" = var.name },
    var.labels,
  )

  body = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = merge(
      { name = var.name },
      { labels = local.all_labels },
      length(var.annotations) > 0 ? { annotations = var.annotations } : {},
    )
  }
}
```

### Design Decisions

| Decision | Rationale |
|---|---|
| Include injected labels in body (not `ignore_changes`) | `ignore_changes` hides ALL label changes, including intentional ones. Including the known injected label is more precise. |
| `merge()` with user labels last | User labels override the injected default if there's a key collision (unlikely but safe). |
| Always include `labels` block on namespaces | The auto-injected label means `labels` is never truly empty on a namespace, so skip the `length(var.labels) > 0` conditional. |

---

## 17. Token Expiry Tracking — Preventing Auth Header Drift

### Problem

When a custom Terraform provider generates short-lived tokens (e.g., Kubernetes ServiceAccount tokens) and stores them via `header`, the token is stored in Terraform state. On every `Read()`, if the provider regenerates the token unconditionally, the new token differs from the stored one, causing `header` drift on every plan for all resources that reference it.

### Solution

Track the token expiry timestamp in state. Only regenerate the token when it's within a buffer period of expiration (e.g., 5 minutes). This keeps the token stable across reads while ensuring it's refreshed before it expires.

```go
// In Read() — only regenerate when near expiry
if !state.TokenExpiry.IsNull() {
    expiry, err := time.Parse(time.RFC3339, state.TokenExpiry.ValueString())
    if err == nil && time.Now().Before(expiry.Add(-5*time.Minute)) {
        // Token still valid — keep existing token, skip regeneration
        resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
        return
    }
}
// Token expired or near expiry — regenerate
```

### Design Decisions

| Decision | Rationale |
|---|---|
| 5-minute buffer before expiry | Prevents edge cases where the token expires between plan and apply |
| `token_expiry` as `Computed` string | Users don't set it — it's derived from `token_duration_seconds` at create/update time |
| RFC3339 format | Standard, parseable, human-readable in state |
| Combined with `header` (not `ephemeral_header`) | `header` is stored in state and available during Delete. Token stability prevents drift. See [Pattern #14](#14-ephemeral_header--not-available-during-delete). |

---

## 18. Post-Create Connectivity Wait (`rest_operation` Polling)

### Problem

Some Azure resources report `provisioningState = "Succeeded"` on the ARM side while an agent component still needs time to bootstrap and call back. For example, Azure Arc connected clusters move from `Connecting` → `Connected` only after the Arc agent pods start on the target cluster and complete their handshake with Azure. Terraform finishes before the cluster is actually usable, and subsequent plans show output drift (`Connecting` → `Connected`).

### Solution

Add a `rest_operation` with a `poll` block that GETs the resource and waits for the secondary status field to reach the desired value. The operation depends on the main resource, ensuring it runs after provisioning completes.

```hcl
resource "rest_operation" "wait_for_connection" {
  count  = var.wait_for_connection ? 1 : 0
  path   = local.resource_path
  method = "GET"

  query = {
    api-version = [local.api_version]
  }

  poll = {
    status_locator    = "body.properties.connectivityStatus"
    default_delay_sec = 15
    status = {
      success = "Connected"
      pending = ["Connecting"]
    }
  }

  output_attrs = toset([
    "properties.connectivityStatus",
    "properties.agentVersion",
    "properties.kubernetesVersion",
  ])

  depends_on = [rest_resource.main_resource]
}
```

### Design Decisions

| Decision | Rationale |
|---|---|
| `rest_operation` (not `rest_resource`) | One-shot fire-and-forget — no lifecycle management needed for a wait operation |
| `poll` (not `poll_create`) | `rest_operation` uses `poll`, not `poll_create`. The `poll_create` attribute is only available on `rest_resource`. |
| `method = "GET"` | Read-only polling — the operation doesn't mutate anything |
| `count = var.wait_for_connection ? 1 : 0` | Opt-in/opt-out per use case. Default `true` for production, can disable for iterative dev |
| `depends_on` | Ensures the wait runs only after the ARM resource is fully provisioned |
| Output used for richer connectivity info | The wait operation's output captures the final `Connected` state with agent version, node count, etc. |

### When to use this pattern

Any resource where ARM provisioning completes before the resource is fully operational:

| Resource | Primary status | Secondary status | Wait target |
|---|---|---|---|
| **Arc Connected Cluster** | `provisioningState = Succeeded` | `connectivityStatus` | `Connected` |
| **AKS Cluster** | `provisioningState = Succeeded` | Agent pool readiness | N/A (handled by ARM) |
| **Arc-enabled Server** | `provisioningState = Succeeded` | `status` | `Connected` |

### Common mistake

```hcl
# ❌ BAD — rest_operation does NOT support poll_create
resource "rest_operation" "wait" {
  poll_create = { ... }  # Error: Unsupported argument
}

# ✅ GOOD — use poll for rest_operation
resource "rest_operation" "wait" {
  poll = { ... }
}
```

---

## 19. `force_new_attrs` — Immutable Body Properties

### Problem

Some Azure resource properties are **immutable after creation**. Attempting an in-place update returns a 400 error (e.g. `RoleAssignmentUpdateNotPermitted` when changing `principalId` on a role assignment, or changing `issuer`/`subject` on a federated identity credential). Terraform's default behaviour is to attempt an update, which fails.

### Solution

Add `force_new_attrs` to the `rest_resource` block listing the immutable body property paths. When any of these change, the provider destroys the old resource and creates a new one instead of attempting an in-place update.

```hcl
resource "rest_resource" "role_assignment" {
  path          = local.ra_path
  create_method = "PUT"

  body = local.body

  # principalId is immutable — Azure rejects updates with 400
  # RoleAssignmentUpdateNotPermitted. Force destroy+create on change.
  force_new_attrs = toset([
    "properties.principalId",
  ])
}
```

### How to Identify Immutable Properties

1. Check the Azure REST API spec — look for properties marked as `x-ms-mutability: ["create", "read"]` (no `"update"`)
2. Check ARM error codes — if an update attempt returns 400 with a message like `*UpdateNotPermitted` or `*CannotBeChanged`, the property is immutable
3. Common immutable properties:
   - `properties.principalId` on role assignments
   - `properties.issuer` and `properties.subject` on federated identity credentials
   - `properties.principalType` on role assignments
   - `properties.roleDefinitionId` on role assignments (scope change)

### When NOT to Use

- For properties that **can** be updated in-place — only use `force_new_attrs` for genuinely immutable properties
- For the resource path itself — path changes already trigger replacement automatically

---

## 20. Provider-Level Retry for Transient Errors

### Problem

Azure ARM operations can fail with transient errors that succeed on retry:
- **409** — concurrent writes on the same parent resource (e.g. `ConcurrentFederatedIdentityCredentialsWritesForSingleManagedIdentity` when creating multiple FICs on the same UAI)
- **429** — ARM request throttling
- **500/502/503** — transient backend failures

Without provider-level retry, these require manual `terraform apply` re-runs.

### Solution

Configure `client.retry` in the provider block to automatically retry on transient status codes:

```hcl
provider "rest" {
  base_url = "https://management.azure.com"

  # ...auth config...

  client = {
    retry = {
      status_codes    = [409, 429, 500, 502, 503]
      count           = 5
      wait_in_sec     = 2
      max_wait_in_sec = 120
    }
  }
}
```

### Design Decisions

| Decision | Rationale |
|---|---|
| Include 409 | Azure FIC concurrent write errors are transient — the second write succeeds after the first completes |
| Include 429 | ARM throttling is by design transient — wait and retry |
| `count = 5` | Enough retries for concurrent FIC writes (typically resolves in 2–3 retries) |
| `wait_in_sec = 2` | Short initial backoff; provider uses exponential backoff up to `max_wait_in_sec` |
| `max_wait_in_sec = 120` | Caps wait at 2 minutes — long enough for ARM throttle windows |

### When to Use

- **Always** on the root module provider for Azure ARM — transient errors are inherent to ARM operations at scale
- Particularly important when creating multiple resources on the same parent (e.g. FICs on a UAI, role assignments on a subscription)

---

## 21. Subscription `scope` Output for Cross-Subscription Role Assignments

### Problem

When creating role assignments scoped to a subscription, the `scope` path (`/subscriptions/{id}`) must be known. If the subscription is managed by Terraform (e.g. via the subscription module), its `subscriptionId` is only available in `rest_resource.*.output.properties.subscriptionId` — known after apply. The role assignment module needs this at plan time for path construction.

### Solution

Add a `scope` output to the subscription module that constructs the ARM-scoped path from the API-sourced subscription ID:

```hcl
# modules/azure/subscription/outputs.tf
output "scope" {
  description = "The subscription-scoped ARM path (/subscriptions/{id}), known after apply."
  value       = try("/subscriptions/${rest_resource.subscription.output.properties.subscriptionId}", null)
}
```

In the YAML configuration, role assignments reference this via `ref:`:

```yaml
azure_role_assignments:
  platform_networking_owner:
    scope: ref:azure_subscriptions.platform_networking.scope
    principal_id: ref:azure_user_assigned_identities.platform_networking.principal_id
    role_definition_id: /providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635
    principal_type: ServicePrincipal
```

### Key Point

A UAI in subscription A can hold an Owner role assignment scoped to subscription B. The UAI's location and the role assignment's scope are independent.
