#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/actions/common.sh
source "$SCRIPT_DIRECTORY/common.sh"

run_preflight_checks

echo "Building SwiftFulcrum"
swift build \
  --package-path "$PROJECT_ROOT" \
  --build-path "$BUILD_ROOT" \
  --disable-sandbox
