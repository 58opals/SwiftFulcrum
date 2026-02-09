#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/actions/common.sh
source "$SCRIPT_DIRECTORY/common.sh"

run_preflight_checks

branch_name="$(current_branch_name)"
if is_worktree_checkout; then
  worktree_status="yes"
else
  worktree_status="no"
fi

echo "Doctor checks passed"
echo "Branch: $branch_name"
echo "Worktree checkout: $worktree_status"
echo "Swift: $(swift_version_line)"
echo "Build root: $BUILD_ROOT"
echo "Cache root: $CACHE_ROOT"
