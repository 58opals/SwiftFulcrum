#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/actions/common.sh
source "$SCRIPT_DIRECTORY/common.sh"

run_preflight_checks
require_command xcode-select

echo "Running setup checks"
echo "Developer directory: $(xcode-select -p)"
echo "Swift: $(swift_version_line)"
run_swift_toolchain_probe

test_list_log="$TMPDIR/test-list.stderr"
if ! swift test list \
  "${SWIFTPM_SHARED_ARGUMENTS[@]}" \
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
