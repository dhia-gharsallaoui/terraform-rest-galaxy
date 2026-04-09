# terraform-rest-galaxy — Claude Code guide

This repo ships versioned Terraform modules that drive Azure, Microsoft Entra ID, GitHub and Kubernetes APIs through the **`LaurentLesle/rest`** Terraform provider. There is NO `azurerm`, `azuread`, `github` or `hashicorp/kubernetes` usage — every resource is expressed as `rest_resource` / `rest_operation` calls against the official REST spec.

The repo was originally scaffolded with a full GitHub Copilot workspace (agents, skills, prompts, instructions, MCP servers). Claude Code has been wired up to use the same knowledge base; the mapping is below.

## Layout

- `modules/{azure,entraid,github,k8s}/<name>/` — versioned sub-modules
- `azure_*.tf`, `entraid_*.tf`, `github_*.tf`, `k8s_*.tf` — root wiring (`for_each` over YAML config)
- `configurations/*.yaml` — per-deployment configs (resources, refs, optional `terraform_backend`)
- `examples/<provider>/<module>/{minimum,complete}/` — example usages used by tests
- `tests/` — `terraform test` files (symlinks into categorised subdirs; see testing instructions)
- `.github/` — canonical Copilot knowledge base (agents, skills, prompts, instructions, patterns, MCP servers)
- `.claude/` — Claude Code adapter (skills, subagents, slash commands) that delegate into `.github/`
- `memories/repo/` — durable repo facts (codebase facts, test conventions)
- `specs/` — vendored REST API spec repos (shallow submodules, consumed by the `*-specs` MCP servers)
- `providers/terraform-provider-rest/` — vendored **writable** copy of the `LaurentLesle/rest` provider source (shallow submodule). Use this to reproduce provider bugs, prototype fixes, and contribute PRs upstream without leaving the repo.

## How Claude Code uses the Copilot assets

| Copilot | Claude Code | Notes |
|---|---|---|
| `.github/skills/<name>/SKILL.md` | `.claude/skills/<name>/` (symlinks) | Invoke via the Skill tool or `/tf-<name>` slash commands |
| `.github/agents/<name>.agent.md` | `.claude/agents/<name>.md` | Thin subagent wrappers that Read and follow the full Copilot agent spec |
| `.github/prompts/<name>.prompt.md` | `.claude/commands/<name>.md` | Slash commands |
| `.github/instructions/*.instructions.md` | Referenced from here + applied when the relevant glob matches | `applyTo` is advisory; apply when editing matching files |
| `.github/patterns/rest-provider-patterns.md` | Referenced from agents/skills | Canonical rest-provider patterns |
| `.vscode/mcp.json` | `.mcp.json` | Same servers, `${workspaceFolder}` → `${CLAUDE_PROJECT_DIR}` |

## Available slash commands

- `/tf-module <resource|scenario>` — scaffold a new module or end-to-end config
- `/tf-fix <module|all>` — audit and reconcile a module against its spec
- `/tf-import <scope>` — discover Azure resources and import them safely
- `/tf-test <module> [complete|minimum]` — `terraform init` + `plan` against an example
- `/tf-diagram <config.yaml>` — generate a Draw.io architecture diagram
- `/tf-diagram-update [description]` — refresh an existing diagram after config changes
- `/tf-backend <config.yaml>` — add a `terraform_backend` block to a YAML config
- `/tfstate-boundary <config.yaml | bootstrap | status>` — manage state boundaries

## Available subagents

- `azure-rest-module` — Azure ARM REST → module generator (uses `azure-specs` MCP)
- `entraid-graph-module` — Microsoft Graph → module generator (uses `msgraph-specs` MCP)
- `github-rest-module` — GitHub REST → module generator (uses `github-specs` MCP)
- `kubernetes-api-module` — Kubernetes API → module generator (uses `kubernetes-specs` MCP)

Each subagent's full instructions live in `.github/agents/<name>.agent.md` and are loaded on first turn.

## Instructions to apply automatically

When editing files matching these globs, consult the corresponding instruction file:

- `**/*.tftest.hcl` → `.github/instructions/testing.instructions.md` (symlinks pattern, categorised dirs, unit vs integration)
- `**/CHANGELOG.md`, `**/.github/workflows/release.yml`, `**/RELEASE_NOTES_TEMPLATE.md` → `.github/instructions/release-notes.instructions.md` (Conventional Commits, upgrade priority, structured notes)
- `**/*.drawio` → `.github/instructions/drawio-azure-icons.instructions.md` (prefer Azure vendor icons, orthogonal edges, hub-and-spoke layout)

## Provider rules (hard)

- Use `LaurentLesle/rest` only. Never add `azurerm`, `azuread`, `integrations/github`, `hashicorp/github`, or `hashicorp/kubernetes`.
- `rest_resource` for full CRUD lifecycles (anything with PUT/GET/DELETE in the spec). `rest_operation` only for POST-only imperative actions.
- API versions, property names, and paths must match the upstream REST spec — cross-check via the relevant `*-specs` MCP server before editing.
- Adoption of existing cloud resources is handled via `check_existance = true`, not manual state edits. `terraform destroy` is forbidden inside `/tf-import`.

## Contributing to the `rest` provider

The provider source is vendored as a shallow submodule at `providers/terraform-provider-rest/` so you can reproduce bugs, prototype fixes, and open upstream PRs without leaving this repo. Use this workflow whenever a module hits a genuine provider limitation (missing attribute, broken polling, incorrect CRUD mapping, etc.) — **never** paper over it with hacks in the module.

### Loop: hit a limitation → fix it → validate → PR

1. **Reproduce** the limitation from a minimal example under `examples/<provider>/<module>/minimum/`. Capture the failing plan/apply error or drift.
2. **Edit the provider** in `providers/terraform-provider-rest/` (Go). Keep changes focused on the smallest fix; write or extend a Go unit test under `providers/terraform-provider-rest/internal/...` covering the behavior.
3. **Build and install locally** with the existing helper:
   ```
   .github/scripts/setup-providers.sh
   ```
   It defaults to `providers/terraform-provider-rest`, runs `go build`, installs the binary into `$HOME/.terraform.d/plugins/registry.terraform.io/LaurentLesle/rest/<version>/<os_arch>/`, and writes `~/.terraformrc` with a `filesystem_mirror` block pinned to that path. Re-run the script after every source change.
4. **Validate end-to-end** — run the provider's own Go tests first, then the Terraform layer:
   ```
   (cd providers/terraform-provider-rest && go test ./...)
   /tf-test <module> minimum     # or complete
   terraform test                 # full suite if the change is broad
   ```
   Make sure the affected example's plan is clean and `terraform test` still passes across unrelated modules.
5. **Commit inside the submodule**. Submodules have their own git history:
   ```
   cd providers/terraform-provider-rest
   git checkout -b fix/<short-description>
   git commit -am "fix: <short description>"
   git push <your-fork> fix/<short-description>
   ```
   Open a PR against `LaurentLesle/terraform-provider-rest` from your fork. Reference the failing example and include the Go test.
6. **Bump the gitlink** in the superproject once the upstream PR merges:
   ```
   git -C providers/terraform-provider-rest fetch --depth=1 origin main
   git -C providers/terraform-provider-rest checkout <merged-sha>
   cd <repo-root>
   git add providers/terraform-provider-rest
   git commit -m "chore(provider): bump rest provider to <sha>"
   ```
   Then bump `required_providers { rest = { version = "~> X.Y" } }` in affected modules if the upstream release also pushed a new tag.

### Guardrails

- **Never hack around a provider limitation in a module** if the correct fix is in the provider. The module layer must stay declarative and spec-accurate.
- **Do not commit binaries** — the plugin mirror under `$HOME/.terraform.d/plugins/` is intentionally outside the repo.
- **CI still checks out the provider separately** via `actions/checkout` in `.github/workflows/terraform-test.yml`; the submodule is purely for the local dev loop. When you bump the submodule gitlink, also bump the pinned version the workflows reference if they pin a tag.
- **Upstream first** — if you find yourself maintaining a long-lived local diff, your PR is overdue.

## MCP servers

Configured in `.mcp.json`. Each spec server reads from a vendored git submodule under `specs/`. After cloning this repo run:

```
git submodule update --init --recommend-shallow --depth 1
```

to populate the four spec trees. Paths in `.mcp.json` are relative to the repo root — no per-machine edits needed.

On startup each spec server auto-fetches its submodule's upstream HEAD (shallow, throttled to once per `MCP_SPECS_UPDATE_INTERVAL_HOURS` hours, default 24). Set `MCP_SPECS_AUTOUPDATE=0` to disable (e.g. when offline). A successful update fast-forwards the submodule working tree, which dirties the superproject's gitlink — commit the bump when convenient. The shared helper lives in `.github/mcp/_spec_updater.py`.

- `azure-specs` → `specs/azure-rest-api-specs/specification`
- `msgraph-specs` → `specs/msgraph-metadata`
- `github-specs` → `specs/rest-api-description`
- `kubernetes-specs` → `specs/kubernetes`
- `drawio` → drawio-mcp-server (needs a `.drawio` file open in an editor)

### Do not Grep/Glob inside `specs/**` when the spec MCP servers are up

The four vendored spec submodules contain tens of thousands of YAML/JSON
files (`azure-rest-api-specs` alone is 60k+ specs across hundreds of
services). Running `Grep`, `Glob`, or the Explore subagent against
`specs/**` will blow up context, waste wall time, and is *almost never*
what you actually want — the MCP servers already index these trees and
expose purpose-built tools.

**Rule:** if the matching `*-specs` MCP server is listed as healthy in
`/mcp`, you MUST query it via its MCP tools instead of searching the
files directly. Use the files only as a last-resort fallback when:

- the server is missing or errored in `/doctor` / `/mcp`, **or**
- the MCP tool surface genuinely doesn't expose what you need (e.g. raw
  example payloads that only exist on disk), **and** you've confirmed
  that by trying the relevant MCP tool first.

Concretely:

| Looking for | Use |
|---|---|
| Azure RP API version, property, path, operation, or examples | `azure-specs` MCP tools — not `Grep specs/azure-rest-api-specs/**` |
| Microsoft Graph endpoint, schema, or permission | `msgraph-specs` MCP tools |
| GitHub REST endpoint, parameter, or response | `github-specs` MCP tools |
| Kubernetes API resource, version, or OpenAPI schema | `kubernetes-specs` MCP tools |

This rule applies to subagents too — when dispatching an `Explore`
agent, tell it to query the MCP servers rather than walk the submodules.

## Memory

Durable repo knowledge lives in `memories/repo/` — `codebase-facts.md`, `test-conventions.md`, plus entries under `.github/memories/repo/`. Prefer reading those before re-discovering facts by grepping.
