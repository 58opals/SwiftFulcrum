#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/../.." && pwd)"
CACHE_ROOT="$PROJECT_ROOT/.codex-cache"
BUILD_ROOT="$PROJECT_ROOT/.build"

export CLANG_MODULE_CACHE_PATH="$CACHE_ROOT/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$CACHE_ROOT/swiftpm-module-cache"
export TMPDIR="$CACHE_ROOT/tmp"

prepare_cache_directories() {
  mkdir -p \
    "$CACHE_ROOT" \
    "$CLANG_MODULE_CACHE_PATH" \
    "$SWIFTPM_MODULECACHE_OVERRIDE" \
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

require_codex_cache_gitignore_entry() {
  local gitignore_path="$PROJECT_ROOT/.gitignore"
  if [[ ! -f "$gitignore_path" ]]; then
    echo "error: expected .gitignore at '$gitignore_path'" >&2
    exit 1
  fi
  if ! grep -Fq ".codex-cache/" "$gitignore_path"; then
    echo "error: .gitignore must include '.codex-cache/' for local cache hygiene" >&2
    exit 1
  fi
}

is_worktree_checkout() {
  git -C "$PROJECT_ROOT" worktree list --porcelain | grep -Fqx "worktree $PROJECT_ROOT"
}

swift_version_line() {
  swift --version | head -n 1
}

run_preflight_checks() {
  require_command swift
  require_command git
  prepare_cache_directories
  require_git_worktree
  require_attached_branch
  require_codex_cache_gitignore_entry
}
