#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/actions/common.sh
source "$SCRIPT_DIRECTORY/common.sh"

run_preflight_checks
require_command xcode-select
require_command swiftc

echo "Running setup checks"
echo "Developer directory: $(xcode-select -p)"
echo "Swift: $(swift_version_line)"

swift_probe_file="$TMPDIR/swift_probe.swift"
swift_probe_error="$TMPDIR/swift_probe.stderr"
printf 'import Foundation\n' > "$swift_probe_file"

if ! swiftc -typecheck \
  -module-cache-path "$SWIFTPM_MODULECACHE_OVERRIDE" \
  "$swift_probe_file" \
  >/dev/null 2>"$swift_probe_error"; then
  echo "error: Swift compiler preflight failed for the current toolchain and SDK." >&2
  cat "$swift_probe_error" >&2
  echo "hint: align your selected developer directory with your installed SDK/toolchain versions." >&2
  exit 1
fi

test_list_log="$TMPDIR/test-list.stderr"
if ! swift test list \
  --package-path "$PROJECT_ROOT" \
  --build-path "$BUILD_ROOT" \
  --disable-sandbox \
  >/dev/null 2>"$test_list_log"; then
  echo "error: SwiftPM could not compile test targets in this environment." >&2
  if grep -Fq "no such module 'Testing'" "$test_list_log"; then
    echo "hint: Swift Testing is unavailable. Select a full Xcode developer directory." >&2
  else
    echo "hint: verify DEVELOPER_DIR and toolchain/SDK alignment, then retry." >&2
  fi
  cat "$test_list_log" >&2
  exit 1
fi

echo "Setup checks passed"
echo "Environment is ready for Doctor, Build, and Test actions."
