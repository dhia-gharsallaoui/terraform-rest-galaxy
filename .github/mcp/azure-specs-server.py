#!/usr/bin/env python3
"""
Azure REST API Specs MCP Server

Parses the local azure-rest-api-specs repository to discover services,
planes (resource-manager / data-plane), providers, resource types, and API
versions.  No network calls — everything is read from the local filesystem.

Directory layouts handled transparently:
  <service>/<plane>/<provider>/stable|preview/<version>/          (flat)
  <service>/<plane>/<provider>/<resource_type>/stable|preview/<version>/  (with resource type)

Environment:
  AZURE_SPECS_ROOT  — path to the specification/ folder
                      (default: specs/azure-rest-api-specs/specification, relative to repo root)
"""

import sys
import json
import os
import datetime
from pathlib import Path

# ── Debug log (helps diagnose VS Code MCP startup issues) ────────────────────
_LOG_PATH = os.environ.get("AZURE_SPECS_LOG", "/tmp/azure-specs-mcp.log")


def _log(msg: str) -> None:
    try:
        ts = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
        with open(_LOG_PATH, "a") as f:
            f.write(f"{ts} {msg}\n")
    except Exception:
        pass

SPECS_ROOT = Path(
    os.environ.get(
        "AZURE_SPECS_ROOT",
        "specs/azure-rest-api-specs/specification",
    )
)

# ── Keep the backing submodule fresh on startup ───────────────────────────────
sys.path.insert(0, str(Path(__file__).parent))
try:
    from _spec_updater import ensure_latest

    ensure_latest(SPECS_ROOT.parent, log=_log)
except Exception as _exc:  # pragma: no cover - defensive
    _log(f"spec auto-update skipped: {_exc!r}")

# ── MCP JSON-RPC transport ────────────────────────────────────────────────
# MCP stdio uses newline-delimited JSON: one complete JSON object per line.
# NO Content-Length headers — that is the LSP/language-server protocol, not MCP.
#
# Reading: sys.stdin.buffer.readline() — blocks until \n, safe with pipes.
# Writing: os.write(1, ...) — single syscall, bypasses Python output buffering.


def _read_message() -> dict | None:
    """
    Read one newline-delimited JSON-RPC message from stdin.
    Returns parsed dict, or None on EOF / decode error.
    """
    while True:
        try:
            line = sys.stdin.buffer.readline()
        except Exception as exc:
            _log(f"stdin read error: {exc}")
            return None
        if not line:                    # EOF
            _log("EOF on stdin")
            return None
        line = line.strip()
        if not line:                    # blank line — skip
            continue
        try:
            return json.loads(line)
        except json.JSONDecodeError as exc:
            _log(f"JSON error: {exc}  raw={line[:120]!r}")
            continue                    # skip malformed line, keep reading


def _send(data: dict) -> None:
    frame = json.dumps(data, ensure_ascii=False).encode("utf-8") + b"\n"
    os.write(1, frame)  # fd 1 = stdout


def _ok(req_id, result) -> None:
    _send({"jsonrpc": "2.0", "id": req_id, "result": result})


def _err(req_id, code: int, message: str) -> None:
    _send({"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}})


# ── Internal helpers ──────────────────────────────────────────────────────────

_SKIP_DIRS = frozenset({"examples", "common", "generated", ".git", "node_modules"})


def _is_version_container(p: Path) -> bool:
    """A version container is a directory whose children include stable/ and/or preview/."""
    return (p / "stable").is_dir() or (p / "preview").is_dir()


def _find_version_containers(root: Path, max_depth: int = 6) -> list[Path]:
    """Recursively find all version-container directories under root."""
    if max_depth <= 0:
        return []
    if _is_version_container(root):
        return [root]
    results: list[Path] = []
    try:
        for child in sorted(root.iterdir()):
            if child.is_dir() and child.name not in _SKIP_DIRS:
                results.extend(_find_version_containers(child, max_depth - 1))
    except PermissionError:
        pass
    return results


def _versions_for_container(container: Path) -> list[dict]:
    """Return all versions (stable + preview) for a version-container, sorted newest first."""
    versions: list[dict] = []
    for stability in ("stable", "preview"):
        stab_dir = container / stability
        if not stab_dir.is_dir():
            continue
        for vdir in stab_dir.iterdir():
            if not vdir.is_dir():
                continue
            swagger_files = sorted(
                f.name for f in vdir.iterdir()
                if f.suffix == ".json" and f.name not in _SKIP_DIRS
            )
            versions.append(
                {"version": vdir.name, "stability": stability, "swagger_files": swagger_files}
            )
    versions.sort(key=lambda x: x["version"], reverse=True)
    return versions


_ext_file_cache: dict[str, dict] = {}


def _load_json_cached(path: Path) -> dict:
    """Load and cache a JSON file by resolved absolute path."""
    key = str(path)
    if key not in _ext_file_cache:
        _ext_file_cache[key] = json.loads(path.read_text(encoding="utf-8"))
    return _ext_file_cache[key]


def _navigate_pointer(doc: dict, pointer: str) -> dict:
    """Navigate a JSON pointer (e.g. 'definitions/Foo') within a document."""
    node = doc
    for part in pointer.split("/"):
        if isinstance(node, dict):
            node = node.get(part, {})
        else:
            return {}
    return node if isinstance(node, dict) else {}


def _resolve_ref(ref: str, spec: dict, base_dir: Path | None = None) -> dict:
    """
    Resolve a JSON $ref — both local (#/definitions/Foo) and external
    (../../common-types/.../types.json#/definitions/Sku).
    base_dir is the directory of the current spec file, needed for external refs.
    """
    if ref.startswith("#/"):
        return _navigate_pointer(spec, ref[2:])

    # External $ref: split into file path and optional JSON pointer
    if "#" in ref:
        file_part, pointer = ref.split("#", 1)
        pointer = pointer.lstrip("/")
    else:
        file_part, pointer = ref, ""

    if not base_dir or not file_part:
        return {}

    resolved_path = (base_dir / file_part).resolve()
    if not resolved_path.is_file():
        return {}

    try:
        ext_doc = _load_json_cached(resolved_path)
    except Exception:
        return {}

    if pointer:
        return _navigate_pointer(ext_doc, pointer)
    return ext_doc if isinstance(ext_doc, dict) else {}


def _inline_schema(schema: dict, spec: dict, depth: int = 0, base_dir: Path | None = None) -> dict:
    """Inline $refs up to 4 levels deep so callers see concrete property lists including enums."""
    if depth > 4:
        return schema
    if "$ref" in schema:
        resolved = _resolve_ref(schema["$ref"], spec, base_dir)
        # For external refs, update base_dir to the resolved file's directory
        ref = schema["$ref"]
        new_base = base_dir
        if not ref.startswith("#/") and base_dir and "#" in ref:
            file_part = ref.split("#", 1)[0]
            new_base = (base_dir / file_part).resolve().parent
        return _inline_schema(resolved, spec, depth + 1, new_base)
    result = dict(schema)
    if "properties" in result:
        result["properties"] = {
            k: _inline_schema(v, spec, depth + 1, base_dir)
            for k, v in result["properties"].items()
        }
    # Inline items schema (for arrays)
    if "items" in result and isinstance(result["items"], dict):
        result["items"] = _inline_schema(result["items"], spec, depth + 1, base_dir)
    # Flatten allOf into properties
    if "allOf" in result:
        merged: dict = {}
        desc = None
        for sub in result["allOf"]:
            inlined = _inline_schema(sub, spec, depth + 1, base_dir)
            merged.update(inlined.get("properties", {}))
            if not desc and inlined.get("description"):
                desc = inlined["description"]
        result.setdefault("properties", {})
        result["properties"] = {**merged, **result["properties"]}
        if desc and "description" not in result:
            result["description"] = desc
        del result["allOf"]
    # Inline additionalProperties
    if "additionalProperties" in result and isinstance(result["additionalProperties"], dict):
        result["additionalProperties"] = _inline_schema(result["additionalProperties"], spec, depth + 1, base_dir)
    return result


def _fallback_version_container(spec_path: str) -> Path | None:
    """
    When spec_path doesn't exist as a directory (e.g. a virtual per-resource
    sub-path like 'network/resource-manager/Microsoft.Network/azureFirewalls'),
    walk up to the parent and search for sibling version containers.

    Returns the first sibling version container found, or None.
    """
    requested = SPECS_ROOT / spec_path
    parent = requested.parent
    if not parent.is_dir():
        return None
    # Search siblings (and their children) for a version container
    containers = _find_version_containers(parent, max_depth=3)
    return containers[0] if containers else None


def _resolve_version_dir(spec_path: str, version: str) -> Path:
    container = SPECS_ROOT / spec_path
    if not container.is_dir():
        fb = _fallback_version_container(spec_path)
        if fb is None:
            raise ValueError(f"Version '{version}' not found under '{spec_path}'")
        container = fb
    stability = "preview" if "preview" in version.lower() else "stable"
    for stab in (stability, "stable", "preview"):
        vdir = container / stab / version
        if vdir.is_dir():
            return vdir
    raise ValueError(f"Version '{version}' not found under '{spec_path}'")


def _pick_swagger_file(version_dir: Path, hint: str = "") -> Path:
    json_files = sorted(
        f for f in version_dir.iterdir()
        if f.suffix == ".json" and f.stem not in _SKIP_DIRS
    )
    if not json_files:
        raise ValueError(f"No swagger JSON files in {version_dir}")
    if hint:
        match = [f for f in json_files if hint.lower() in f.stem.lower()]
        if match:
            return match[0]
    return json_files[0]


# ── Search index for deep find_resource ──────────────────────────────────────

_search_index: dict[str, str] | None = None


def _build_search_index() -> dict[str, str]:
    """
    Build a cached index mapping each spec_path to a compact searchable string
    extracted from its latest swagger files: info title/description, API paths,
    definition names, operationIds, and operation summaries.
    Built lazily on first find_resource call.
    """
    global _search_index
    if _search_index is not None:
        return _search_index

    _log("building search index\u2026")
    index: dict[str, str] = {}
    for container in _find_version_containers(SPECS_ROOT):
        rel = container.relative_to(SPECS_ROOT).as_posix()
        versions = _versions_for_container(container)
        if not versions:
            continue
        latest = versions[0]
        vdir = container / latest["stability"] / latest["version"]
        terms: list[str] = []
        for sf in latest.get("swagger_files", []):
            fpath = vdir / sf
            if not fpath.is_file():
                continue
            try:
                spec = json.loads(fpath.read_text(encoding="utf-8"))
                info = spec.get("info", {})
                terms.append(info.get("title", ""))
                terms.append(info.get("description", ""))
                terms.extend(spec.get("paths", {}).keys())
                terms.extend(spec.get("definitions", {}).keys())
                for methods in spec.get("paths", {}).values():
                    for op in methods.values():
                        if isinstance(op, dict):
                            terms.append(op.get("operationId", ""))
                            terms.append(op.get("summary", ""))
            except Exception:
                pass
        index[rel] = " ".join(terms).lower()

    _search_index = index
    _log(f"search index built: {len(index)} entries")
    return _search_index


# ── Tool implementations ──────────────────────────────────────────────────────

def tool_list_services(args: dict) -> list[str]:
    """List all Azure service folders, optionally filtered by keyword."""
    kw = args.get("keyword", "").lower()
    return sorted(
        d.name for d in SPECS_ROOT.iterdir()
        if d.is_dir() and (not kw or kw in d.name.lower())
    )


def tool_list_planes(args: dict) -> list[str]:
    """List API planes (resource-manager, data-plane) for a service."""
    svc = SPECS_ROOT / args["service"]
    if not svc.is_dir():
        raise ValueError(f"Service '{args['service']}' not found")
    return sorted(
        d.name for d in svc.iterdir()
        if d.is_dir() and d.name in {"resource-manager", "data-plane"}
    )


def tool_find_resource(args: dict) -> list[dict]:
    """
    Search for services, providers, and resource types matching a keyword.
    Matches against directory path parts AND swagger content (API paths,
    definitions, operation IDs, summaries, and spec title/description).
    Returns spec_path (relative to SPECS_ROOT), latest stable and overall latest version.
    """
    kw = args["keyword"].lower()
    index = _build_search_index()
    results: list[dict] = []
    seen: set[str] = set()
    for container in _find_version_containers(SPECS_ROOT):
        rel = container.relative_to(SPECS_ROOT).as_posix()
        if rel in seen:
            continue
        parts = rel.split("/")
        # Match on directory path parts (fast path)
        matched = any(kw in p.lower() for p in parts)
        # Match on swagger content (deep search)
        if not matched and rel in index:
            matched = kw in index[rel]
        if matched:
            seen.add(rel)
            versions = _versions_for_container(container)
            latest_stable = next((v for v in versions if v["stability"] == "stable"), None)
            latest_any = versions[0] if versions else None
            results.append({
                "spec_path": rel,
                "latest_stable_version": latest_stable["version"] if latest_stable else None,
                "latest_version": latest_any["version"] if latest_any else None,
                "latest_stability": latest_any["stability"] if latest_any else None,
            })
    return results


def tool_list_api_versions(args: dict) -> list[dict]:
    """
    List all API versions (stable + preview) for a spec_path, sorted newest first.
    If spec_path is not a version container (e.g. a provider root), all children
    version containers are returned grouped.

    Fallback: when spec_path doesn't exist as a directory (e.g. a virtual
    per-resource sub-path like 'Microsoft.Network/azureFirewalls'), walks up to
    the parent and searches for sibling version containers.
    """
    p = SPECS_ROOT / args["spec_path"]
    if not p.is_dir():
        fb = _fallback_version_container(args["spec_path"])
        if fb is None:
            raise ValueError(f"Path not found: {args['spec_path']}")
        p = fb
    if _is_version_container(p):
        return _versions_for_container(p)
    # Not a direct container — find children
    containers = _find_version_containers(p, max_depth=4)
    if not containers:
        raise ValueError(f"No version containers found under: {args['spec_path']}")
    return [
        {"spec_path": c.relative_to(SPECS_ROOT).as_posix(),
         "versions": _versions_for_container(c)}
        for c in containers
    ]


def tool_latest_stable_version(args: dict) -> dict | None:
    """
    Return the latest stable API version for a spec_path.
    Falls back to the latest preview if no stable version exists.
    """
    result = tool_list_api_versions(args)
    # Flat list case
    if result and "stability" in result[0]:
        stable = [v for v in result if v["stability"] == "stable"]
        return stable[0] if stable else (result[0] if result else None)
    # Grouped case (multiple sub-containers)
    out = []
    for group in result:
        versions = group["versions"]
        stable = [v for v in versions if v["stability"] == "stable"]
        best = stable[0] if stable else (versions[0] if versions else None)
        out.append({"spec_path": group["spec_path"], "best_version": best})
    return out


def _resolve_spec_file(args: dict) -> Path:
    """Resolve the swagger file path from tool arguments."""
    vdir = _resolve_version_dir(args["spec_path"], args["version"])
    f = (vdir / args["swagger_file"]) if args.get("swagger_file") else _pick_swagger_file(vdir)
    if not f.is_file():
        raise ValueError(f"File not found: {f}")
    return f


def tool_read_spec(args: dict) -> dict:
    """
    Read and return the raw Swagger/OpenAPI JSON for a specific version.
    spec_path must be the version-container path (same format as find_resource returns).
    """
    f = _resolve_spec_file(args)
    return json.loads(f.read_text(encoding="utf-8"))


def tool_get_spec_summary(args: dict) -> dict:
    """
    Return a compact summary of a swagger spec including:
    - info (title, description, API version)
    - all paths with method, operationId, summary, long-running flag,
      Retry-After / async options, path+query parameters
    - inlined request body schema for PUT/PATCH/POST operations
    - list of read-only properties (marked x-ms-mutability or readOnly)

    Use this instead of read_spec when you only need to understand the API shape.
    """
    spec_file = _resolve_spec_file(args)
    spec = json.loads(spec_file.read_text(encoding="utf-8"))
    base_dir = spec_file.parent
    info = spec.get("info", {})

    # Collect read-only property names from definitions
    readonly_props: dict[str, list[str]] = {}
    for def_name, schema in spec.get("definitions", {}).items():
        ro = []
        for prop, pschema in schema.get("properties", {}).items():
            mutability = pschema.get("x-ms-mutability", [])
            if pschema.get("readOnly") or (mutability and "write" not in mutability):
                ro.append(prop)
        if ro:
            readonly_props[def_name] = ro

    paths_summary = []
    for path, methods in spec.get("paths", {}).items():
        for method, op in methods.items():
            if not isinstance(op, dict) or method.startswith("x-"):
                continue

            # Resolve $ref in parameters (both path-level and operation-level)
            raw_params = list(methods.get("parameters", []))  # path-level params
            raw_params.extend(op.get("parameters", []))       # operation-level params
            resolved_params = []
            for p in raw_params:
                if isinstance(p, dict) and "$ref" in p:
                    resolved_params.append(_resolve_ref(p["$ref"], spec, base_dir))
                elif isinstance(p, dict):
                    resolved_params.append(p)

            entry: dict = {
                "path": path,
                "method": method.upper(),
                "operation_id": op.get("operationId"),
                "summary": (op.get("summary") or op.get("description") or "")[:200],
                "long_running": op.get("x-ms-long-running-operation", False),
                "long_running_final_state_via": (
                    op.get("x-ms-long-running-operation-options", {}).get("final-state-via")
                ),
                "path_parameters": [
                    p["name"] for p in resolved_params
                    if isinstance(p, dict) and p.get("in") == "path"
                ],
                "required_query_params": [
                    p["name"] for p in resolved_params
                    if isinstance(p, dict) and p.get("in") == "query" and p.get("required")
                ],
            }
            # Retry-After: ARM standard; surfaced when the op is long-running
            if entry["long_running"]:
                entry["retry_after_header"] = True  # ARM always emits Retry-After on async ops

            # Body schema for write operations
            if method.upper() in ("PUT", "PATCH", "POST"):
                for param in resolved_params:
                    if isinstance(param, dict) and param.get("in") == "body":
                        schema = param.get("schema", {})
                        inlined = _inline_schema(schema, spec, base_dir=base_dir)
                        entry["body_schema"] = inlined
                        # Annotate which top-level props are read-only
                        props = inlined.get("properties", {})
                        entry["writable_properties"] = [
                            k for k, v in props.items()
                            if not v.get("readOnly") and "write" in v.get("x-ms-mutability", ["write"])
                        ]
                        entry["readonly_properties"] = [
                            k for k, v in props.items()
                            if v.get("readOnly") or (
                                v.get("x-ms-mutability") and "write" not in v["x-ms-mutability"]
                            )
                        ]
                        break
                # OpenAPI 3.x requestBody
                if "requestBody" in op:
                    for ct, media in op["requestBody"].get("content", {}).items():
                        if "json" in ct:
                            inlined = _inline_schema(media.get("schema", {}), spec, base_dir=base_dir)
                            entry["body_schema"] = inlined
                            break

            paths_summary.append(entry)

    return {
        "title": info.get("title"),
        "description": info.get("description"),
        "spec_api_version": info.get("version"),
        "host": spec.get("host"),
        "base_path": spec.get("basePath"),
        "paths": paths_summary,
        "readonly_properties_by_definition": readonly_props,
    }


# ── Tool registry ─────────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "list_services",
        "description": (
            "List all Azure service folder names in the local azure-rest-api-specs/specification "
            "directory. Optionally filter by keyword. Use this as the starting point to discover "
            "which service owns a resource type."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "keyword": {
                    "type": "string",
                    "description": "Optional case-insensitive substring filter (e.g. 'storage', 'network')"
                }
            },
        },
    },
    {
        "name": "list_planes",
        "description": (
            "List the API planes available for a service: "
            "'resource-manager' (ARM control plane) and/or 'data-plane'."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["service"],
            "properties": {
                "service": {
                    "type": "string",
                    "description": "Service folder name, e.g. 'resources', 'storage', 'network'"
                }
            },
        },
    },
    {
        "name": "find_resource",
        "description": (
            "Search across ALL services, providers, and resource types for a keyword. "
            "Matches against directory path parts AND swagger content (API paths, "
            "definition names, operation IDs, summaries, and spec title/description). "
            "Returns matching spec_path values (relative to specification/) along with "
            "the latest stable and latest overall API version. "
            "Use this to locate the spec_path to pass to list_api_versions / get_spec_summary."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["keyword"],
            "properties": {
                "keyword": {
                    "type": "string",
                    "description": "Case-insensitive substring matched against service, provider, resource_type path names AND swagger content (API paths, definitions, operationIds, summaries, title, description). E.g. 'resourcegroup', 'virtualnetwork', 'storageaccount', 'tenant', 'ciam'"
                }
            },
        },
    },
    {
        "name": "list_api_versions",
        "description": (
            "List all API versions (stable + preview) for a spec_path, sorted newest first. "
            "Each entry includes: version, stability ('stable'|'preview'), swagger_files. "
            "spec_path should come from find_resource output."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["spec_path"],
            "properties": {
                "spec_path": {
                    "type": "string",
                    "description": "Path relative to specification/, e.g. 'resources/resource-manager/Microsoft.Resources/resources'"
                }
            },
        },
    },
    {
        "name": "latest_stable_version",
        "description": (
            "Return the latest stable API version object for a spec_path. "
            "Falls back to the latest preview if no stable version exists. "
            "Returns: {version, stability, swagger_files}."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["spec_path"],
            "properties": {
                "spec_path": {
                    "type": "string",
                    "description": "Path relative to specification/, as returned by find_resource"
                }
            },
        },
    },
    {
        "name": "get_spec_summary",
        "description": (
            "Return a compact, structured summary of a swagger spec for a specific API version. "
            "Includes: title, description, all API paths with HTTP method, operationId, summary, "
            "long-running flag, Retry-After annotation, path/query parameters, inlined request body "
            "schema for write operations, and writable vs read-only property lists. "
            "PREFER this over read_spec — it extracts only what is needed to generate Terraform modules."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["spec_path", "version"],
            "properties": {
                "spec_path": {
                    "type": "string",
                    "description": "Version-container path relative to specification/, e.g. 'resources/resource-manager/Microsoft.Resources/resources'"
                },
                "version": {
                    "type": "string",
                    "description": "API version string, e.g. '2025-04-01'"
                },
                "swagger_file": {
                    "type": "string",
                    "description": "Specific swagger filename (optional; auto-selected if omitted)"
                },
            },
        },
    },
    {
        "name": "read_spec",
        "description": (
            "Read and return the FULL raw Swagger/OpenAPI JSON for a specific API version. "
            "Warning: files can be large. Use get_spec_summary instead unless you need the raw spec."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["spec_path", "version"],
            "properties": {
                "spec_path": {
                    "type": "string",
                    "description": "Version-container path relative to specification/"
                },
                "version": {
                    "type": "string",
                    "description": "API version string, e.g. '2025-04-01'"
                },
                "swagger_file": {
                    "type": "string",
                    "description": "Specific swagger filename (optional)"
                },
            },
        },
    },
]

TOOL_FNS = {
    "list_services": tool_list_services,
    "list_planes": tool_list_planes,
    "find_resource": tool_find_resource,
    "list_api_versions": tool_list_api_versions,
    "latest_stable_version": tool_latest_stable_version,
    "get_spec_summary": tool_get_spec_summary,
    "read_spec": tool_read_spec,
}

# ── Request handler ───────────────────────────────────────────────────────────

def _handle(msg: dict) -> None:
    method = msg.get("method", "")
    req_id = msg.get("id")
    params = msg.get("params") or {}

    if method == "initialize":
        _ok(req_id, {
            "protocolVersion": "2024-11-05",
            "serverInfo": {"name": "azure-specs", "version": "1.0.0"},
            "capabilities": {"tools": {}},
        })

    elif method in ("notifications/initialized", "initialized"):
        pass  # notification — no response

    elif method == "tools/list":
        _ok(req_id, {"tools": TOOLS})

    elif method == "tools/call":
        name = params.get("name", "")
        arguments = params.get("arguments") or {}
        fn = TOOL_FNS.get(name)
        if fn is None:
            _err(req_id, -32601, f"Unknown tool: {name}")
            return
        try:
            result = fn(arguments)
            _ok(req_id, {
                "content": [{"type": "text", "text": json.dumps(result, indent=2, ensure_ascii=False)}]
            })
        except Exception as exc:
            _ok(req_id, {
                "content": [{"type": "text", "text": f"Error: {exc}"}],
                "isError": True,
            })

    elif req_id is not None:
        _err(req_id, -32601, f"Method not found: {method}")


def main() -> None:
    _log(f"azure-specs-server started  SPECS_ROOT={SPECS_ROOT}")
    while True:
        try:
            msg = _read_message()
            if msg is None:  # EOF or unrecoverable error
                _log("shutting down")
                break
            method = msg.get("method", "<no method>")
            _log(f"recv method={method!r} id={msg.get('id')!r}")
            _handle(msg)
        except Exception as exc:
            _log(f"unhandled error: {exc}")
            sys.stderr.write(f"azure-specs-server error: {exc}\n")
            sys.stderr.flush()


if __name__ == "__main__":
    main()
