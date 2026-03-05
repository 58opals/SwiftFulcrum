#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

allowlist_file="config/public-api-root-allowlist.txt"

if [[ ! -f "$allowlist_file" ]]; then
    echo "Missing allowlist file: $allowlist_file"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Missing required tool: jq"
    exit 1
fi

tmp_current="$(mktemp)"
tmp_known="$(mktemp)"
tmp_new="$(mktemp)"
trap 'rm -f "$tmp_current" "$tmp_known" "$tmp_new"' EXIT

swift package --disable-sandbox dump-symbol-graph --minimum-access-level public >/dev/null

symbol_file="$(find .build -type f -path '*/symbolgraph/SwiftFulcrum.symbols.json' | LC_ALL=C sort | head -n 1)"
if [[ -z "$symbol_file" ]]; then
    echo "Unable to locate SwiftFulcrum symbol graph output."
    exit 1
fi

jq -r '.symbols[] | (.pathComponents[0] // empty)' "$symbol_file" \
    | grep -vE '^[[:space:]]*$' \
    | LC_ALL=C sort -u > "$tmp_current"

grep -vE '^[[:space:]]*($|#)' "$allowlist_file" | LC_ALL=C sort -u > "$tmp_known"

comm -23 "$tmp_current" "$tmp_known" > "$tmp_new"

if [[ -s "$tmp_new" ]]; then
    echo "Public facade boundary check failed."
    echo "Unexpected exported public root symbols:"
    cat "$tmp_new"
    exit 1
fi

echo "Public facade boundary check passed."
