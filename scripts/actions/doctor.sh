#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/actions/common.sh
source "$SCRIPT_DIRECTORY/common.sh"

run_preflight_checks
run_swift_toolchain_probe

branch_name="$(current_branch_name)"
if is_worktree_checkout; then
  worktree_status="yes"
elif [[ "${ALLOW_NON_WORKTREE_CHECKOUT:-0}" == "1" ]]; then
  worktree_status="no (override enabled)"
else
  echo "error: checkout is not a registered git worktree for this path." >&2
  echo "hint: use a worktree checkout or set ALLOW_NON_WORKTREE_CHECKOUT=1 for a one-off local edit." >&2
  exit 1
fi

echo "Doctor checks passed"
echo "Branch: $branch_name"
echo "Worktree checkout: $worktree_status"
echo "Swift: $(swift_version_line)"
echo "Build root: $BUILD_ROOT"
echo "Cache root: $CACHE_ROOT"
echo "SwiftPM cache path: $SWIFTPM_CACHE_PATH"
echo "SwiftPM config path: $SWIFTPM_CONFIG_PATH"
echo "SwiftPM security path: $SWIFTPM_SECURITY_PATH"
