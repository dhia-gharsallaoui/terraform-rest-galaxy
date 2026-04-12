#!/usr/bin/env python3
"""
generate-docs.py — Generate docs/yaml-reference.md from Terraform root module variable definitions.

For each resource type (azure_*, entraid_*, github_*, k8s_*) it emits:
  - Description
  - Attributes table (name, type, required, default)
  - YAML example converted from the HCL example in the description

Usage:
    python3 scripts/generate-docs.py
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
BUILD_DIR = REPO_ROOT / ".build"
DOCS_DIR = REPO_ROOT / "docs"

# Files to skip within each provider glob (non-resource files)
SKIP_SUFFIXES = {
    "_variables.tf", "_outputs.tf", "_layers.tf",
    "_provider.tf", "_versions.tf",
}

# Provider groups: (heading, slug, file glob, extra skips)
PROVIDERS = [
    ("Azure", "azure", "azure_*.tf", set()),
    ("Entra ID", "entraid", "entraid_*.tf", set()),
    ("GitHub", "github", "github_*.tf", set()),
    ("Kubernetes", "k8s", "k8s_*.tf", set()),
]


# ── Parsing helpers ────────────────────────────────────────────────────────────

def _find_variable_blocks(content: str) -> list[tuple[str, str]]:
    """Return list of (var_name, block_body) for every `variable "..." { }` in content."""
    results = []
    pos = 0
    while True:
        m = re.search(r'\bvariable\s+"(\w+)"\s*\{', content[pos:])
        if not m:
            break
        name = m.group(1)
        brace_start = pos + m.end() - 1  # index of opening {
        depth, j = 0, brace_start
        while j < len(content):
            if content[j] == '{':
                depth += 1
            elif content[j] == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        results.append((name, content[brace_start + 1:j]))
        pos = pos + m.end()
    return results


def _extract_description(block: str) -> str:
    """Extract description string from a variable block (heredoc or quoted)."""
    # heredoc: description = <<-MARKER\n...\nMARKER
    m = re.search(r'description\s*=\s*<<-(\w+)\n(.*?)\n[ \t]*\1(?:\s|$)', block, re.DOTALL)
    if m:
        return _dedent(m.group(2))
    # single-quoted (rare) or double-quoted
    m = re.search(r'description\s*=\s*"((?:[^"\\]|\\.)*)"', block, re.DOTALL)
    if m:
        return m.group(1).replace('\\"', '"')
    return ""


def _dedent(text: str) -> str:
    """Remove common leading whitespace from a multiline string."""
    lines = text.split('\n')
    non_empty = [l for l in lines if l.strip()]
    if not non_empty:
        return text
    indent = min(len(l) - len(l.lstrip()) for l in non_empty)
    return '\n'.join(l[indent:] for l in lines)


def _extract_type_body(block: str) -> str:
    """Return the full `type = ...` value from a variable block."""
    m = re.search(r'\btype\s*=\s*', block)
    if not m:
        return ""
    start = m.end()
    depth_p = depth_b = 0
    i = start
    while i < len(block):
        c = block[i]
        if c == '(':
            depth_p += 1
        elif c == ')':
            depth_p -= 1
            if depth_p <= 0 and depth_b <= 0:
                i += 1
                break
        elif c == '{':
            depth_b += 1
        elif c == '}':
            depth_b -= 1
            if depth_b < 0 and depth_p <= 0:
                break
        elif c == '\n' and depth_p == 0 and depth_b == 0:
            break
        i += 1
    return block[start:i].strip()


def _extract_object_attrs(type_str: str) -> list[dict]:
    """
    Parse map(object({...})) and return list of top-level attribute dicts:
      {name, type, required, default, comment}
    Nested objects/lists are collapsed to a simplified type label.
    """
    # Find the outermost object({...}) content
    m = re.search(r'object\s*\(\s*\{', type_str)
    if not m:
        return []

    # Find the matching closing }), accounting for nesting
    start = m.end()
    depth = 1
    i = start
    while i < len(type_str) and depth > 0:
        c = type_str[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
        i += 1
    obj_body = type_str[start:i - 1]

    attrs = []
    j = 0
    lines = obj_body.splitlines()
    line_idx = 0

    while line_idx < len(lines):
        line = lines[line_idx]

        # Strip inline comment but save it
        comment_m = re.search(r'#(.*)$', line)
        comment = comment_m.group(1).strip() if comment_m else ""
        line_clean = re.sub(r'#.*$', '', line).strip().rstrip(',')
        line_idx += 1

        if not line_clean:
            continue

        # attr_name = <type_expr_start>
        attr_m = re.match(r'^(\w+)\s*=\s*(.*)$', line_clean)
        if not attr_m:
            continue

        attr_name = attr_m.group(1)
        type_start = attr_m.group(2).strip()

        # If the type expression opens a brace/paren that isn't closed on this
        # line, collect subsequent lines until balanced.
        full_expr = type_start
        open_count = full_expr.count('(') + full_expr.count('{')
        close_count = full_expr.count(')') + full_expr.count('}')

        while open_count > close_count and line_idx < len(lines):
            next_line = re.sub(r'#.*$', '', lines[line_idx]).strip()
            line_idx += 1
            full_expr += ' ' + next_line
            open_count += next_line.count('(') + next_line.count('{')
            close_count += next_line.count(')') + next_line.count('}')

        full_expr = full_expr.strip().rstrip(',')
        required, default_val, attr_type = True, None, full_expr

        opt_m = re.match(r'^optional\s*\((.+)\)\s*$', full_expr, re.DOTALL)
        if opt_m:
            required = False
            inner = opt_m.group(1)
            split = _split_first_comma(inner)
            if split:
                attr_type = split[0].strip()
                default_val = split[1].strip()
            else:
                attr_type = inner.strip()

        attrs.append({
            "name": attr_name,
            "type": _simplify_type(attr_type),
            "required": required,
            "default": default_val,
            "comment": comment,
        })
    return attrs


def _split_first_comma(s: str) -> tuple[str, str] | None:
    """Split string at the first top-level comma (outside parens/brackets/braces)."""
    depth = 0
    for i, c in enumerate(s):
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        elif c == ',' and depth == 0:
            return s[:i], s[i + 1:]
    return None


def _simplify_type(t: str) -> str:
    """Return a readable type label, collapsing nested objects."""
    t = t.strip()
    if re.match(r'^object\s*\(', t):
        return 'object'
    if re.match(r'^list\s*\(\s*object', t):
        return 'list(object)'
    if re.match(r'^map\s*\(\s*object', t):
        return 'map(object)'
    if re.match(r'^list\s*\(\s*string', t):
        return 'list(string)'
    if re.match(r'^map\s*\(\s*string', t):
        return 'map(string)'
    if re.match(r'^list\s*\(\s*number', t):
        return 'list(number)'
    return t


# ── HCL → YAML conversion ──────────────────────────────────────────────────────

def _hcl_example_to_yaml(hcl: str) -> str:
    """
    Convert an HCL assignment/map block to YAML syntax.
    Input is the raw text from the 'Example:' section of a description.
    """
    lines = hcl.splitlines()
    out = []
    brace_stack = []  # track open { to know when to close

    for raw_line in lines:
        # Preserve inline comments
        comment = ""
        comment_m = re.search(r'\s+#(.*)$', raw_line)
        if comment_m:
            comment = "  #" + comment_m.group(1)
            raw_line = raw_line[:comment_m.start()]

        # Strip standalone comment lines
        stripped = raw_line.strip()
        if stripped.startswith('#'):
            continue
        if not stripped:
            continue

        indent = len(raw_line) - len(raw_line.lstrip())
        stripped = stripped.rstrip(',')

        # Key = { → key:  (with optional inline content)
        m = re.match(r'^(\S+)\s*=\s*\{(.*)$', stripped)
        if m:
            key = m.group(1)
            remainder = m.group(2).strip().rstrip('}').rstrip(',').strip()
            out.append((' ' * indent) + key + ':' + comment)
            if remainder:
                # Inline map entries: "k1 = v1, k2 = v2"
                for entry in re.split(r',\s*', remainder):
                    entry = entry.strip()
                    if not entry:
                        continue
                    entry_m = re.match(r'^(\S+)\s*=\s*(.+)$', entry)
                    if entry_m:
                        out.append((' ' * (indent + 2)) + entry_m.group(1) + ': ' + entry_m.group(2).strip())
                    else:
                        out.append((' ' * (indent + 2)) + entry)
            continue

        # Bare { → skip
        if stripped == '{':
            continue

        # Bare } or }, → skip
        if re.match(r'^\}[,]?$', stripped):
            continue

        # Key = value
        m = re.match(r'^(\S+)\s*=\s*(.+)$', stripped)
        if m:
            key = m.group(1)
            val = m.group(2).strip().rstrip(',')
            out.append((' ' * indent) + key + ': ' + val + comment)
            continue

        # Bare key (map key without =)
        out.append((' ' * indent) + stripped + ':' + comment)

    # Normalize: remove common leading indent
    return _dedent('\n'.join(out))


def _extract_yaml_example(description: str) -> str:
    """Extract and convert the HCL Example block from a description to YAML."""
    m = re.search(r'Example:\s*\n(.*?)(?:\Z|(?=\n[^\s]))', description, re.DOTALL)
    if not m:
        return ""
    hcl = _dedent(m.group(1))
    yaml = _hcl_example_to_yaml(hcl)
    return yaml.strip()


def _short_description(description: str) -> str:
    """Return just the prose part (before 'Example:')."""
    m = re.search(r'\n\s*Example:', description)
    prose = description[:m.start()] if m else description
    return prose.strip()


# ── Markdown generation ────────────────────────────────────────────────────────

def _render_variable(name: str, description: str, type_str: str, api_version: str | None = None) -> str:
    """Render a full markdown section for one resource variable."""
    attrs = _extract_object_attrs(type_str)
    prose = _short_description(description)
    yaml_example = _extract_yaml_example(description)

    lines = []
    lines.append(f"### `{name}`\n")
    if api_version:
        lines.append(f"**API version:** `{api_version}`\n")
    if prose:
        lines.append(prose + "\n")

    if attrs:
        lines.append("#### Attributes\n")
        lines.append("| Name | Type | Required | Default | Description |")
        lines.append("|------|------|:--------:|---------|-------------|")
        for a in attrs:
            req = "yes" if a["required"] else "no"
            default = f"`{a['default']}`" if a["default"] is not None else "—"
            comment = a["comment"] if a["comment"] else ""
            lines.append(
                f"| `{a['name']}` | `{a['type']}` | {req} | {default} | {comment} |"
            )
        lines.append("")

    if yaml_example:
        lines.append("#### YAML Example\n")
        lines.append("```yaml")
        lines.append(yaml_example)
        lines.append("```\n")

    lines.append("---\n")
    return '\n'.join(lines)


def _is_resource_variable(name: str, type_str: str) -> bool:
    """True if this variable represents a YAML-configurable resource map."""
    return bool(re.match(r'^map\s*\(\s*object', type_str))


def _extract_module_source(tf_content: str) -> str | None:
    """Return the module source path from a root .tf file (e.g. './modules/azure/resource_group')."""
    m = re.search(r'\bmodule\s+"\w+"\s*\{[^}]*source\s*=\s*"([^"]+)"', tf_content, re.DOTALL)
    return m.group(1) if m else None


def _read_api_version(module_source: str) -> str | None:
    """
    Read the API version from a module, trying several patterns:
      1. outputs.tf: output "api_version" { value = "..." }
      2. main.tf:    api_version = "YYYY-MM-DD..."          (Azure ARM)
      3. main.tf:    #   api        : <label>               (Entra ID / GitHub / K8s)
      4. main.tf:    # Source: <label>                      (K8s)
    """
    module_dir = REPO_ROOT / module_source.lstrip("./")

    # 1. outputs.tf output block
    outputs_path = module_dir / "outputs.tf"
    if outputs_path.exists():
        m = re.search(
            r'output\s+"api_version"\s*\{[^}]*value\s*=\s*"([^"]+)"',
            outputs_path.read_text(), re.DOTALL,
        )
        if m:
            return m.group(1)

    main_path = module_dir / "main.tf"
    if not main_path.exists():
        return None
    content = main_path.read_text()

    # 2. Azure ARM: api_version = "YYYY-MM-DD..."
    m = re.search(r'\bapi_version\s*=\s*"([0-9]{4}-[0-9]{2}-[0-9]{2}[^"]*)"', content)
    if m:
        return m.group(1)

    # 3. Entra ID / GitHub comment: #   api        : <label>
    m = re.search(r'#\s+api\s*:\s*(.+)', content)
    if m:
        return m.group(1).strip()

    # 4. Kubernetes comment: # Source: <label>
    m = re.search(r'#\s+Source:\s*(.+)', content)
    if m:
        return m.group(1).strip()

    return None


# ── Main ───────────────────────────────────────────────────────────────────────

def main() -> None:
    DOCS_DIR.mkdir(parents=True, exist_ok=True)

    index_lines: list[str] = []
    index_lines.append("""\
# YAML Configuration Reference

All resources that can be created with terraform-rest-galaxy are declared in YAML
configuration files. Each top-level key maps directly to a Terraform variable name.

Values prefixed with `ref:` are resolved at plan time against the reference context:

```yaml
resource_group_name: ref:azure_resource_groups.app.resource_group_name
location:           ref:azure_resource_groups.app.location
```

---

## Providers

""")

    total_resources = 0

    # The flat .tf files live in .build/ (assembled by scripts/build-galaxy.sh).
    if not BUILD_DIR.is_dir():
        print(f"ERROR: {BUILD_DIR} does not exist. Run scripts/build-galaxy.sh first.", file=sys.stderr)
        sys.exit(1)

    for heading, slug, glob_pattern, extra_skip in PROVIDERS:
        files = sorted(BUILD_DIR.glob(glob_pattern))
        resource_files = [
            f for f in files
            if not any(str(f).endswith(s) for s in SKIP_SUFFIXES | extra_skip)
        ]

        provider_vars: list[tuple[str, str, str, str | None]] = []

        for tf_file in resource_files:
            content = tf_file.read_text()
            module_source = _extract_module_source(content)
            api_version = _read_api_version(module_source) if module_source else None
            for var_name, block in _find_variable_blocks(content):
                type_str = _extract_type_body(block)
                if not _is_resource_variable(var_name, type_str):
                    continue
                description = _extract_description(block)
                provider_vars.append((var_name, description, type_str, api_version))

        if not provider_vars:
            continue

        # Write per-provider file
        out_file = DOCS_DIR / f"yaml-reference-{slug}.md"
        sections: list[str] = []
        sections.append(f"# YAML Reference — {heading}\n")
        sections.append(f"← [Back to index](yaml-reference.md)\n")
        for name, description, type_str, api_version in provider_vars:
            sections.append(_render_variable(name, description, type_str, api_version))
        out_file.write_text('\n'.join(sections))

        count = len(provider_vars)
        total_resources += count
        print(f"Generated: {out_file.relative_to(REPO_ROOT)}  ({count} resources)")

        # Add entry to index
        resource_list = "\n".join(
            f"  - [`{name}`](yaml-reference-{slug}.md#{name.replace('_', '-')})"
            for name, _, _, _ in provider_vars
        )
        index_lines.append(
            f"### [{heading}](yaml-reference-{slug}.md) — {count} resources\n\n{resource_list}\n"
        )

    # Write index
    index_file = DOCS_DIR / "yaml-reference.md"
    index_file.write_text('\n'.join(index_lines))
    print(f"Generated: {index_file.relative_to(REPO_ROOT)}  (index, {total_resources} total resources)")


if __name__ == "__main__":
    main()
