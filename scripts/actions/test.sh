#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/actions/common.sh
source "$SCRIPT_DIRECTORY/common.sh"

run_preflight_checks

echo "Testing SwiftFulcrum"
swift test "${SWIFTPM_SHARED_ARGUMENTS[@]}"
