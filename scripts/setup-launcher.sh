#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"

cd "$PROJECT_ROOT"

if git symbolic-ref --quiet --short HEAD >/dev/null 2>&1; then
  make Setup
else
  echo "Setup deferred: detached HEAD. Run Setup after attaching a branch."
fi
