#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/../.." && pwd)"
CACHE_ROOT="$PROJECT_ROOT/.workspace-cache"
BUILD_ROOT="$PROJECT_ROOT/.build"
SWIFTPM_CACHE_PATH="$CACHE_ROOT/swiftpm-cache"
SWIFTPM_CONFIG_PATH="$CACHE_ROOT/swiftpm-config"
SWIFTPM_SECURITY_PATH="$CACHE_ROOT/swiftpm-security"

export CLANG_MODULE_CACHE_PATH="$CACHE_ROOT/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$CACHE_ROOT/swiftpm-module-cache"
export TMPDIR="$CACHE_ROOT/tmp"

SWIFTPM_SHARED_ARGUMENTS=(
  --package-path "$PROJECT_ROOT"
  --build-path "$BUILD_ROOT"
  --cache-path "$SWIFTPM_CACHE_PATH"
  --config-path "$SWIFTPM_CONFIG_PATH"
  --security-path "$SWIFTPM_SECURITY_PATH"
  --manifest-cache local
  --disable-sandbox
)

find_preferred_xcode_developer_directory() {
  local candidate_directory
  local -a candidate_directories=(
    "/Applications/Xcode.app/Contents/Developer"
    "/Applications/Xcode-beta.app/Contents/Developer"
    "$HOME/Applications/Xcode.app/Contents/Developer"
    "$HOME/Applications/Xcode-beta.app/Contents/Developer"
  )

  for candidate_directory in "${candidate_directories[@]}"; do
    if [[ -d "$candidate_directory" ]]; then
      echo "$candidate_directory"
      return 0
    fi
  done

  return 1
}

effective_developer_directory() {
  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    echo "$DEVELOPER_DIR"
    return 0
  fi

  xcode-select -p 2>/dev/null || true
}

use_preferred_xcode_developer_directory() {
  require_command xcode-select

  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    return 0
  fi

  local selected_developer_directory
  selected_developer_directory="$(xcode-select -p 2>/dev/null || true)"

  if [[ "$selected_developer_directory" == *"/CommandLineTools"* || -z "$selected_developer_directory" ]]; then
    local preferred_developer_directory
    if preferred_developer_directory="$(find_preferred_xcode_developer_directory)"; then
      export DEVELOPER_DIR="$preferred_developer_directory"
      echo "Using Xcode developer directory: $DEVELOPER_DIR"
    fi
  fi
}

prepare_cache_directories() {
  mkdir -p \
    "$CACHE_ROOT" \
    "$CLANG_MODULE_CACHE_PATH" \
    "$SWIFTPM_MODULECACHE_OVERRIDE" \
    "$SWIFTPM_CACHE_PATH" \
    "$SWIFTPM_CONFIG_PATH" \
    "$SWIFTPM_SECURITY_PATH" \
    "$TMPDIR"
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "error: required command '$command_name' was not found in PATH" >&2
    exit 1
  fi
}

require_git_worktree() {
  if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: '$PROJECT_ROOT' is not inside a git worktree" >&2
    exit 1
  fi
}

current_branch_name() {
  git -C "$PROJECT_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

require_attached_branch() {
  local branch_name
  branch_name="$(current_branch_name)"
  if [[ -z "$branch_name" ]]; then
    echo "error: detached HEAD detected. Create or switch to a task branch first." >&2
    exit 1
  fi
}

require_workspace_cache_gitignore_entry() {
  local gitignore_path="$PROJECT_ROOT/.gitignore"
  if [[ ! -f "$gitignore_path" ]]; then
    echo "error: expected .gitignore at '$gitignore_path'" >&2
    exit 1
  fi
  if ! grep -Fq ".workspace-cache/" "$gitignore_path"; then
    echo "error: .gitignore must include '.workspace-cache/' for local cache hygiene" >&2
    exit 1
  fi
}

is_worktree_checkout() {
  git -C "$PROJECT_ROOT" worktree list --porcelain | grep -Fqx "worktree $PROJECT_ROOT"
}

swift_version_line() {
  swift --version | head -n 1
}

run_swift_toolchain_probe() {
  require_command swiftc
  local swift_probe_file="$TMPDIR/swift_probe.swift"
  local swift_probe_error="$TMPDIR/swift_probe.stderr"
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
}

run_preflight_checks() {
  use_preferred_xcode_developer_directory
  require_command swift
  require_command git
  prepare_cache_directories
  require_git_worktree
  require_attached_branch
  require_workspace_cache_gitignore_entry
}
