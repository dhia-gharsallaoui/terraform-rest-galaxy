#!/usr/bin/env python3
"""
Microsoft Graph API Specs MCP Server

Parses the local microsoftgraph/msgraph-metadata repository to discover
API versions, search paths, and inspect operation details from the
OpenAPI v3 specs.

The Graph metadata repo has this layout:
  openapi/
    v1.0/openapi.yaml   (stable — ~760K lines)
    beta/openapi.yaml    (preview — ~1.5M lines)

Because the files are massive, specs are parsed lazily on first use and
cached in memory.  Path indexing is built once per version.

Environment:
  MSGRAPH_SPECS_ROOT  — path to the msgraph-metadata repo root
                        (default: specs/msgraph-metadata, relative to repo root)
"""

import sys
import json
import os
import datetime
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None  # handled at tool call time with a clear error

# ── Debug log ─────────────────────────────────────────────────────────────────
_LOG_PATH = os.environ.get("MSGRAPH_SPECS_LOG", "/tmp/msgraph-specs-mcp.log")


def _log(msg: str) -> None:
    try:
        ts = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
        with open(_LOG_PATH, "a") as f:
            f.write(f"{ts} {msg}\n")
    except Exception:
        pass


REPO_ROOT = Path(
    os.environ.get(
        "MSGRAPH_SPECS_ROOT",
        "specs/msgraph-metadata",
    )
)

# ── Keep the backing submodule fresh on startup ───────────────────────────────
sys.path.insert(0, str(Path(__file__).parent))
try:
    from _spec_updater import ensure_latest

    ensure_latest(REPO_ROOT, log=_log)
except Exception as _exc:  # pragma: no cover - defensive
    _log(f"spec auto-update skipped: {_exc!r}")

# ── MCP JSON-RPC transport ────────────────────────────────────────────────────


def _read_message() -> dict | None:
    while True:
        try:
            line = sys.stdin.buffer.readline()
        except Exception as exc:
            _log(f"stdin read error: {exc}")
            return None
        if not line:
            _log("EOF on stdin")
            return None
        line = line.strip()
        if not line:
            continue
        try:
            return json.loads(line)
        except json.JSONDecodeError as exc:
            _log(f"JSON error: {exc}  raw={line[:120]!r}")
            continue


def _send(data: dict) -> None:
    frame = json.dumps(data, ensure_ascii=False).encode("utf-8") + b"\n"
    os.write(1, frame)


def _ok(req_id, result) -> None:
    _send({"jsonrpc": "2.0", "id": req_id, "result": result})


def _err(req_id, code: int, message: str) -> None:
    _send({"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}})


# ── Lazy spec loading & caching ──────────────────────────────────────────────

_spec_cache: dict[str, dict] = {}        # version → parsed spec
_path_index: dict[str, dict] = {}        # version → {path_str: {method: op_dict}}
_resource_groups: dict[str, list] = {}   # version → sorted list of top-level resource groups


def _ensure_yaml():
    if yaml is None:
        raise RuntimeError("PyYAML is required but not installed. Run: pip3 install pyyaml")


def _load_spec(version: str) -> dict:
    """Load and cache the OpenAPI spec for a version (v1.0 or beta)."""
    if version in _spec_cache:
        return _spec_cache[version]
    _ensure_yaml()
    spec_file = REPO_ROOT / "openapi" / version / "openapi.yaml"
    if not spec_file.is_file():
        raise ValueError(f"Spec file not found for version '{version}': {spec_file}")
    _log(f"Loading {spec_file} ...")
    with open(spec_file, "r", encoding="utf-8") as f:
        spec = yaml.safe_load(f)
    _spec_cache[version] = spec
    _log(f"Loaded {version}: {len(spec.get('paths', {}))} paths")
    return spec


def _get_path_index(version: str) -> dict:
    """Build or return the path index: {path_str: {method: operation}}."""
    if version in _path_index:
        return _path_index[version]
    spec = _load_spec(version)
    index = {}
    for path_str, methods in spec.get("paths", {}).items():
        ops = {}
        for method, op in methods.items():
            if isinstance(op, dict) and method in ("get", "post", "put", "patch", "delete"):
                ops[method] = op
        if ops:
            index[path_str] = ops
    _path_index[version] = index
    return index


def _get_resource_groups(version: str) -> list[str]:
    """Return sorted list of top-level resource segments (e.g. 'users', 'groups', 'applications')."""
    if version in _resource_groups:
        return _resource_groups[version]
    index = _get_path_index(version)
    groups = set()
    for path_str in index:
        parts = path_str.strip("/").split("/")
        if parts:
            groups.add(parts[0])
    result = sorted(groups)
    _resource_groups[version] = result
    return result


# ── Schema helpers ────────────────────────────────────────────────────────────


def _resolve_ref(ref: str, spec: dict) -> dict:
    """Resolve a local JSON/YAML $ref (e.g. '#/components/schemas/Foo')."""
    if not ref.startswith("#/"):
        return {}
    node = spec
    for part in ref[2:].split("/"):
        if isinstance(node, dict):
            node = node.get(part, {})
        else:
            return {}
    return node if isinstance(node, dict) else {}


def _inline_schema(schema: dict, spec: dict, depth: int = 0) -> dict:
    """Inline $refs up to 2 levels deep."""
    if depth > 2:
        return schema
    if "$ref" in schema:
        return _inline_schema(_resolve_ref(schema["$ref"], spec), spec, depth + 1)
    result = dict(schema)
    if "properties" in result:
        result["properties"] = {
            k: _inline_schema(v, spec, depth + 1)
            for k, v in result["properties"].items()
        }
    if "allOf" in result:
        merged = {}
        for sub in result["allOf"]:
            inlined = _inline_schema(sub, spec, depth + 1)
            merged.update(inlined.get("properties", {}))
        result.setdefault("properties", {})
        result["properties"] = {**merged, **result["properties"]}
        del result["allOf"]
    return result


# ── Tool implementations ─────────────────────────────────────────────────────


def tool_list_versions(args: dict) -> list[dict]:
    """List available Graph API versions from the openapi/ directory."""
    openapi_dir = REPO_ROOT / "openapi"
    if not openapi_dir.is_dir():
        raise ValueError(f"openapi/ directory not found at {openapi_dir}")
    versions = []
    for d in sorted(openapi_dir.iterdir()):
        if d.is_dir() and (d / "openapi.yaml").is_file():
            versions.append({
                "version": d.name,
                "stability": "stable" if d.name == "v1.0" else "preview",
                "spec_file": f"openapi/{d.name}/openapi.yaml",
            })
    return versions


def tool_list_resources(args: dict) -> list[str]:
    """List top-level resource groups for a version (e.g. 'users', 'groups', 'organization')."""
    version = args.get("version", "v1.0")
    return _get_resource_groups(version)


def tool_find_path(args: dict) -> list[dict]:
    """
    Search for API paths matching a keyword.
    Returns matching paths with their HTTP methods and operation summaries.
    """
    keyword = args["keyword"].lower()
    version = args.get("version", "v1.0")
    method_filter = args.get("method", "").lower()
    limit = min(args.get("limit", 30), 100)

    index = _get_path_index(version)
    results = []

    for path_str, methods in index.items():
        path_lower = path_str.lower()
        for method, op in methods.items():
            if method_filter and method != method_filter:
                continue
            op_id = (op.get("operationId") or "").lower()
            op_summary = (op.get("summary") or "").lower()
            if keyword not in path_lower and keyword not in op_id and keyword not in op_summary:
                continue
            results.append({
                "path": path_str,
                "method": method.upper(),
                "operation_id": op.get("operationId"),
                "summary": (op.get("summary") or op.get("description") or "")[:200],
                "tags": op.get("tags", []),
            })
            if len(results) >= limit:
                break
        if len(results) >= limit:
            break

    return results


def tool_get_operation(args: dict) -> dict:
    """
    Get detailed information about a specific API operation.
    Returns the full operation including parameters, request body schema (inlined),
    and response schemas.
    """
    version = args.get("version", "v1.0")
    path = args["path"]
    method = args["method"].lower()

    spec = _load_spec(version)
    path_entry = spec.get("paths", {}).get(path)
    if not path_entry:
        raise ValueError(f"Path not found: {path}")
    op = path_entry.get(method)
    if not op or not isinstance(op, dict):
        raise ValueError(f"Method {method.upper()} not found for path: {path}")

    result = {
        "path": path,
        "method": method.upper(),
        "operation_id": op.get("operationId"),
        "summary": op.get("summary"),
        "description": (op.get("description") or "")[:500],
        "tags": op.get("tags", []),
        "parameters": [],
    }

    # Parameters
    for param in op.get("parameters", []):
        if isinstance(param, dict):
            if "$ref" in param:
                param = _resolve_ref(param["$ref"], spec)
            result["parameters"].append({
                "name": param.get("name"),
                "in": param.get("in"),
                "required": param.get("required", False),
                "description": (param.get("description") or "")[:200],
                "type": param.get("schema", {}).get("type") if "schema" in param else param.get("type"),
            })

    # Request body
    req_body = op.get("requestBody")
    if req_body:
        if "$ref" in req_body:
            req_body = _resolve_ref(req_body["$ref"], spec)
        for content_type, media in req_body.get("content", {}).items():
            if "json" in content_type:
                schema = media.get("schema", {})
                inlined = _inline_schema(schema, spec)
                result["request_body"] = {
                    "content_type": content_type,
                    "required": req_body.get("required", False),
                    "schema": inlined,
                }
                # Extract writable vs readonly
                props = inlined.get("properties", {})
                result["writable_properties"] = [
                    k for k, v in props.items()
                    if not v.get("readOnly")
                ]
                result["readonly_properties"] = [
                    k for k, v in props.items()
                    if v.get("readOnly")
                ]
                break

    # Response summary (just the success response schema)
    responses = op.get("responses", {})
    for code in ("200", "201", "204"):
        resp = responses.get(code)
        if resp and isinstance(resp, dict):
            for ct, media in resp.get("content", {}).items():
                if "json" in ct:
                    schema = media.get("schema", {})
                    inlined = _inline_schema(schema, spec)
                    result["response_schema"] = inlined
                    break
            break

    return result


def tool_get_resource_summary(args: dict) -> dict:
    """
    Get a summary of all operations for a top-level resource.
    Lists all paths and methods under that resource prefix.
    """
    resource = args["resource"].strip("/")
    version = args.get("version", "v1.0")
    prefix = f"/{resource}"

    index = _get_path_index(version)
    operations = []

    for path_str, methods in index.items():
        if path_str == prefix or path_str.startswith(prefix + "/") or path_str.startswith(prefix + "("):
            for method, op in methods.items():
                operations.append({
                    "path": path_str,
                    "method": method.upper(),
                    "operation_id": op.get("operationId"),
                    "summary": (op.get("summary") or "")[:200],
                })

    if not operations:
        raise ValueError(f"No operations found for resource: {resource}")

    return {
        "resource": resource,
        "version": version,
        "operation_count": len(operations),
        "operations": operations,
    }


# ── Tool registry ─────────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "list_versions",
        "description": (
            "List available Microsoft Graph API versions from the local msgraph-metadata "
            "repo. Returns v1.0 (stable) and beta (preview)."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "list_resources",
        "description": (
            "List top-level resource groups in the Microsoft Graph API "
            "(e.g. 'users', 'groups', 'applications', 'organization', 'tenants'). "
            "Use this to discover what resource types are available."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "version": {
                    "type": "string",
                    "description": "API version: 'v1.0' (stable, default) or 'beta' (preview)",
                    "default": "v1.0",
                },
            },
        },
    },
    {
        "name": "find_path",
        "description": (
            "Search for API paths matching a keyword. Matches against path segments, "
            "operationId, and summary. Returns paths with methods and summaries. "
            "Use this to find specific operations like tenant creation, user management, etc."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["keyword"],
            "properties": {
                "keyword": {
                    "type": "string",
                    "description": "Case-insensitive keyword to search (e.g. 'tenant', 'organization', 'user')",
                },
                "version": {
                    "type": "string",
                    "description": "API version: 'v1.0' (default) or 'beta'",
                    "default": "v1.0",
                },
                "method": {
                    "type": "string",
                    "description": "Filter by HTTP method (e.g. 'post', 'put', 'get'). Empty = all methods.",
                    "default": "",
                },
                "limit": {
                    "type": "integer",
                    "description": "Max results to return (default 30, max 100)",
                    "default": 30,
                },
            },
        },
    },
    {
        "name": "get_operation",
        "description": (
            "Get detailed information about a specific Graph API operation including "
            "parameters, request body schema (inlined), writable/readonly properties, "
            "and response schema. Use after find_path to inspect a specific endpoint."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["path", "method"],
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Full API path (e.g. '/organization', '/users/{user-id}')",
                },
                "method": {
                    "type": "string",
                    "description": "HTTP method (e.g. 'get', 'post', 'patch', 'delete')",
                },
                "version": {
                    "type": "string",
                    "description": "API version: 'v1.0' (default) or 'beta'",
                    "default": "v1.0",
                },
            },
        },
    },
    {
        "name": "get_resource_summary",
        "description": (
            "Get a summary of ALL operations under a top-level resource. "
            "Lists every path and method for the resource (e.g. all /organization/... endpoints). "
            "Use this to understand the full surface area of a resource type."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["resource"],
            "properties": {
                "resource": {
                    "type": "string",
                    "description": "Top-level resource name (e.g. 'organization', 'users', 'groups')",
                },
                "version": {
                    "type": "string",
                    "description": "API version: 'v1.0' (default) or 'beta'",
                    "default": "v1.0",
                },
            },
        },
    },
]

TOOL_FNS = {
    "list_versions": tool_list_versions,
    "list_resources": tool_list_resources,
    "find_path": tool_find_path,
    "get_operation": tool_get_operation,
    "get_resource_summary": tool_get_resource_summary,
}

# ── Request handler ───────────────────────────────────────────────────────────


def _handle(msg: dict) -> None:
    method = msg.get("method", "")
    req_id = msg.get("id")
    params = msg.get("params") or {}

    if method == "initialize":
        _ok(req_id, {
            "protocolVersion": "2024-11-05",
            "serverInfo": {"name": "msgraph-specs", "version": "1.0.0"},
            "capabilities": {"tools": {}},
        })

    elif method in ("notifications/initialized", "initialized"):
        pass

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
    _log(f"msgraph-specs-server started  REPO_ROOT={REPO_ROOT}")
    while True:
        try:
            msg = _read_message()
            if msg is None:
                _log("shutting down")
                break
            method = msg.get("method", "<no method>")
            _log(f"recv method={method!r} id={msg.get('id')!r}")
            _handle(msg)
        except Exception as exc:
            _log(f"unhandled error: {exc}")
            sys.stderr.write(f"msgraph-specs-server error: {exc}\n")
            sys.stderr.flush()


if __name__ == "__main__":
    main()
