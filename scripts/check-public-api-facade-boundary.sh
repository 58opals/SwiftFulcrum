#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

baseline_file="config/public-api-nonfacade-baseline.txt"
allowlist_file="config/public-api-nonfacade-allowlist.txt"

if [[ ! -f "$baseline_file" ]]; then
    echo "Missing baseline file: $baseline_file"
    echo "Run scripts/update-public-api-facade-boundary-baseline.sh first."
    exit 1
fi

scan_public_nonfacade() {
    rg -n --no-heading \
        --glob '*.swift' \
        --glob '!Sources/SwiftFulcrum/PublicAPI/**' \
        -e '^[[:space:]]*(public|open)[[:space:]]+extension\b' \
        -e '^[[:space:]]*(public|open)[[:space:]]+(actor|class|struct|enum|protocol|typealias|var|let|func|subscript|init)\b' \
        Sources/SwiftFulcrum \
    | LC_ALL=C sort -u
}

tmp_current="$(mktemp)"
tmp_known="$(mktemp)"
tmp_new="$(mktemp)"
trap 'rm -f "$tmp_current" "$tmp_known" "$tmp_new"' EXIT

scan_public_nonfacade > "$tmp_current"

{
    grep -vE '^[[:space:]]*($|#)' "$baseline_file" || true
    if [[ -f "$allowlist_file" ]]; then
        grep -vE '^[[:space:]]*($|#)' "$allowlist_file" || true
    fi
} | LC_ALL=C sort -u > "$tmp_known"

comm -23 "$tmp_current" "$tmp_known" > "$tmp_new"

if [[ -s "$tmp_new" ]]; then
    echo "Public facade boundary check failed."
    echo "Unexpected public/open declarations outside Sources/SwiftFulcrum/PublicAPI:"
    cat "$tmp_new"
    exit 1
fi

echo "Public facade boundary check passed."
