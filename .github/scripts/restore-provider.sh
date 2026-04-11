#!/usr/bin/env bash
# Restore a pre-built rest provider from a downloaded artifact.
#
# The artifact is expected to have been uploaded from ~/.terraform.d/plugins/
# and already extracted to the same path by actions/download-artifact.
# This script fixes the executable permission and writes ~/.terraformrc so
# Terraform uses the filesystem mirror instead of the public registry.
#
# Usage: .github/scripts/restore-provider.sh
set -euo pipefail

echo "=== Restoring rest provider from artifact ==="
chmod -R +x "$HOME/.terraform.d/plugins/"

printf 'provider_installation {\n  filesystem_mirror {\n    path    = "%s/.terraform.d/plugins"\n    include = ["registry.terraform.io/laurentlesle/rest"]\n  }\n  direct {}\n}\n' \
  "$HOME" > "$HOME/.terraformrc"

echo "Mirror configured: $HOME/.terraform.d/plugins/"
ls -la "$HOME/.terraform.d/plugins/registry.terraform.io/LaurentLesle/rest/" 2>/dev/null || true
