#!/usr/bin/env bash
# Build and install the rest provider into a local filesystem mirror for development.
# For production, the provider is fetched from the public Terraform registry (LaurentLesle/rest).
# Usage: .github/scripts/setup-providers.sh [rest_src_dir]
#
# The script:
#   1. Builds terraform-provider-rest from Go source (if Go is available)
#      or copies a pre-built binary from the source directory
#   2. Installs the binary into $HOME/.terraform.d/plugins/...
#   3. Writes a .terraformrc that uses dev_overrides for local builds + direct for everything else
set -euo pipefail

REST_SRC="${1:-providers/terraform-provider-rest}"
PROVIDER_VERSION="1.0.0"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  arm64)   ARCH="arm64" ;;
esac
PLUGIN_DIR="$HOME/.terraform.d/plugins/registry.terraform.io/LaurentLesle/rest/${PROVIDER_VERSION}/${OS}_${ARCH}"
BINARY_NAME="terraform-provider-rest_v${PROVIDER_VERSION}"

echo "=== Installing rest provider (${OS}_${ARCH}) ==="
mkdir -p "$PLUGIN_DIR"

if command -v go &>/dev/null && [ -f "$REST_SRC/go.mod" ]; then
  echo "Building from source: $REST_SRC"
  (cd "$REST_SRC" && go build -o "$PLUGIN_DIR/$BINARY_NAME" .)
elif [ -f "$REST_SRC/terraform-provider-rest" ]; then
  echo "Copying pre-built binary from $REST_SRC"
  cp "$REST_SRC/terraform-provider-rest" "$PLUGIN_DIR/$BINARY_NAME"
elif [ -f "$REST_SRC/$BINARY_NAME" ]; then
  echo "Copying pre-built binary from $REST_SRC"
  cp "$REST_SRC/$BINARY_NAME" "$PLUGIN_DIR/$BINARY_NAME"
else
  echo "ERROR: Cannot find Go or pre-built binary in $REST_SRC" >&2
  exit 1
fi

chmod +x "$PLUGIN_DIR/$BINARY_NAME"

echo "=== Writing ~/.terraformrc ==="
cat > "$HOME/.terraformrc" <<EOF
provider_installation {
  filesystem_mirror {
    path    = "$HOME/.terraform.d/plugins"
    include = ["registry.terraform.io/laurentlesle/rest"]
  }
  direct {}
}
EOF

echo "=== Provider installed at ${PLUGIN_DIR} ==="
ls -la "$PLUGIN_DIR"
