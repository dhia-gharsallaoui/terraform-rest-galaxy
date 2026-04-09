# Codebase Facts — Terraform Restful Provider Repo

## Architecture

- **Provider**: `LaurentLesle/rest ~> 1.0` — REST-first, no `azurerm`/`azapi`/`hashicorp/kubernetes`
- **Custom providers**: `rest` (REST API, ref-resolution, K8s token, externals validation) — source vendored as a shallow submodule at `providers/terraform-provider-rest/`
- **Module domains**: `modules/azure/`, `modules/entraid/`, `modules/github/`, `modules/k8s/`
- **Config-driven**: YAML files in `configurations/` define infrastructure via `ref:` cross-references
- **State backend**: `azurerm` in storage account `stdplstate001`

## Key Files

- `providers/terraform-provider-rest/internal/resources/k8s_token.go` — K8s ServiceAccount + bearer token resource with expiry tracking
- `providers/terraform-provider-rest/internal/functions/validate_externals.go` — externals validation with two-pass flattenJSONResponse
- `modules/k8s/namespace/main.tf` — includes `kubernetes.io/metadata.name` auto-injected label
- `modules/azure/container_registry/main.tf` — `poll_delete` treats 404 as success

## Restful Provider Gotchas (Hard-Won)

1. **`ephemeral_header` breaks Delete** — write-only attrs NOT available during Delete. Use `header` + token expiry tracking. (Pattern #14)
2. **ARM `poll_delete` 404 = success** — when polling resource URL after DELETE, 404 means resource is gone. (Pattern #15)
3. **K8s namespace auto-label** — K8s injects `kubernetes.io/metadata.name` on all namespaces. Include in body. (Pattern #16)
4. **Token drift** — tokens regenerated on every Read cause header drift. Track expiry, only regenerate when near expiration. (Pattern #17)
5. **`properties.type` vs top-level `type`** — Go map iteration is random; flattenJSONResponse uses two-pass to prevent `properties.type` overwriting ARM envelope `type`.
6. **PKCS#1 vs PKCS#8** — Azure Arc requires PKCS#1 public key format. `tls_public_key` outputs PKCS#8; strip header with `substr(..., 32, -1)`.

## Build & Test

- Build custom provider: `.github/scripts/setup-providers.sh` (defaults to `providers/terraform-provider-rest`, builds via Go, installs into the local plugin mirror, writes `~/.terraformrc`)
- Install to mirror manually: `cd providers/terraform-provider-rest && go build -o ~/.terraform.d/plugins/registry.terraform.io/LaurentLesle/rest/<version>/<os_arch>/terraform-provider-rest_v<version> .`
- Update lock: delete `.terraform.lock.hcl` → `terraform init -backend=false`
- Run tests: `terraform test` from repo root
- Full lifecycle: `./tf.sh apply <config.yaml>` / `./tf.sh destroy <config.yaml>`

## Active Infrastructure

- Kind clusters: platform (6443), edge (6444) — Azure Arc enrolled
- ACR: `acrarcagents001`
- Subscription: `dd00b1a5-4c67-43da-931a-31a1432b3a20`
- Config: `configurations/k8s_arc_enrollment.yaml`

## Roadmap (Parked)

- **Arc Kubernetes Extensions** — Module ready at `modules/azure/arc_kubernetes_extension/`, root wiring in `azure_arc_kubernetes_extensions.tf`. Uses built-in extension registry with auto-detected node architecture precondition. Blocked on local kind clusters (arm64/Apple Silicon) because several extensions (e.g. `microsoft.monitor.pipelinecontroller`) only ship amd64 images. YAML config commented out. Re-enable when deploying to amd64 clusters.
  - **Remaining work:**
    - Validate the built-in extension registry (`extension_registry` in `main.tf`) against real Azure marketplace data — current entries are best-effort
    - Add more extension types to the registry as they are tested (e.g. `microsoft.azuremonitor.containers`, `microsoft.arcdataservices`)
    - Test full lifecycle (apply + destroy) on an amd64 cluster
    - Handle extensions that require a `plan` block (marketplace extensions with billing)
    - Consider fetching supported architectures dynamically from the Azure Edge Marketplace API instead of a static map
    - Add unit and integration tests (`tests/unit_azure_arc_kubernetes_extension.tftest.hcl`, `tests/integration_azure_arc_kubernetes_extension.tftest.hcl`)
