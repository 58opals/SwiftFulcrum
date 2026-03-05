#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

report_file=".build/reports/naming-audit.txt"
mkdir -p "$(dirname "$report_file")"

changed_files="$(
    {
        git diff --name-only --diff-filter=ACMR
        git diff --cached --name-only --diff-filter=ACMR
        git ls-files --others --exclude-standard
    } | rg '\.swift$' | LC_ALL=C sort -u || true
)"

blocking_count=0
advisory_count=0

disallowed_suffixes=(Factory Service ViewModel Store DataSource Mapper Formatter Manager Handler Helper Provider)
predicate_prefixes=(is has can should supports allows requires needs wants may must)

emit_blocking_rename() {
    local violation="$1"
    local rename="$2"
    local reason="$3"
    local scope="$4"
    {
        echo "BlockingRename"
        echo "Violation: $violation"
        echo "Rename: $rename"
        echo "Reason: $reason"
        echo "Scope: $scope"
        echo
    } >> "$report_file"
    blocking_count=$((blocking_count + 1))
}

emit_blocking_nonrename() {
    local violation="$1"
    local reason="$2"
    local fix="$3"
    local scope="$4"
    {
        echo "BlockingNonRename"
        echo "Violation: $violation"
        echo "Reason: $reason"
        echo "Fix: $fix"
        echo "Scope: $scope"
        echo
    } >> "$report_file"
    blocking_count=$((blocking_count + 1))
}

emit_advisory() {
    local advisory="$1"
    local name="$2"
    local suggestion="$3"
    local reason="$4"
    local scope="$5"
    {
        echo "Advisory"
        echo "Advisory: $advisory"
        echo "Name: $name"
        if [[ -n "$suggestion" ]]; then
            echo "Suggestion: $suggestion"
        fi
        echo "Reason: $reason"
        echo "Scope: $scope"
        echo
    } >> "$report_file"
    advisory_count=$((advisory_count + 1))
}

is_predicate_method_name() {
    local name="$1"
    local prefix
    for prefix in "${predicate_prefixes[@]}"; do
        if [[ "$name" == "$prefix"* ]]; then
            return 0
        fi
    done
    return 1
}

cat > "$report_file" <<EOF
# Swift Naming Audit
Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)

EOF

if [[ -z "$changed_files" ]]; then
    {
        echo "No changed Swift files detected."
        echo
        echo "Summary"
        echo "Blocking: 0"
        echo "Advisory: 0"
    } >> "$report_file"
    echo "Naming audit: no changed Swift files."
    exit 0
fi

while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    scope="Strict"
    if [[ "$file" == Sources/SwiftFulcrum/PublicAPI/* ]]; then
        scope="Facade"
    fi

    while IFS= read -r numbered_line; do
        line_number="${numbered_line%%$'\t'*}"
        line_text="${numbered_line#*$'\t'}"

        if [[ "$scope" == "Facade" ]]; then
            if [[ "$line_text" =~ ^[[:space:]]*(public|open)[[:space:]]+extension[[:space:]]+([^[:space:]]+) ]]; then
                extension_target="${BASH_REMATCH[2]}"
                if [[ "$extension_target" != SwiftFulcrum* ]]; then
                    emit_blocking_nonrename \
                        "PublicFacadeScopeMismatch" \
                        "Facade extension targets must stay within the SwiftFulcrum namespace chain." \
                        "Move this declaration into SwiftFulcrum.* facade chain or mark it internal." \
                        "$file:$line_number declaration '$line_text'"
                fi
            fi

            if [[ "$line_text" =~ ^(public|open)[[:space:]]+(actor|class|struct|enum|protocol)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*) ]]; then
                top_level_name="${BASH_REMATCH[3]}"
                if [[ "$top_level_name" != "SwiftFulcrum" ]]; then
                    emit_blocking_nonrename \
                        "PublicFacadeScopeMismatch" \
                        "Top-level facade declarations must be SwiftFulcrum root declarations or extensions of that root." \
                        "Nest this declaration under SwiftFulcrum via a facade extension file." \
                        "$file:$line_number declaration '$line_text'"
                fi
            fi
        fi

        if [[ "$line_text" =~ ^[[:space:]]*(public|open)[[:space:]]+(actor|class|struct|enum|protocol|typealias)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*) ]]; then
            declared_name="${BASH_REMATCH[3]}"
            for suffix in "${disallowed_suffixes[@]}"; do
                if [[ "$declared_name" == *"$suffix" ]]; then
                    renamed_candidate="${declared_name%$suffix}"
                    if [[ -n "$renamed_candidate" && "$renamed_candidate" != "$declared_name" ]]; then
                        emit_blocking_rename \
                            "DisallowedRoleSuffix" \
                            "$declared_name -> $renamed_candidate" \
                            "Disallowed role suffix '$suffix' is blocking for new or renamed symbols." \
                            "$file:$line_number declaration '$line_text'"
                    else
                        emit_blocking_nonrename \
                            "DisallowedRoleSuffix" \
                            "Disallowed role suffix '$suffix' is blocking for new or renamed symbols." \
                            "Rename this symbol to a role-compliant name without disallowed suffixes." \
                            "$file:$line_number declaration '$line_text'"
                    fi
                fi
            done
        fi

        if [[ "$scope" == "Strict" ]]; then
            if [[ "$line_text" == *"func "* && "$line_text" == *"()"* && "$line_text" == *"->"* && "$line_text" == *"Bool"* ]] \
                && [[ "$line_text" =~ ^[[:space:]]*(public|open|internal|private|fileprivate)?[[:space:]]*func[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\) ]]; then
                method_name="${BASH_REMATCH[2]}"
                if is_predicate_method_name "$method_name"; then
                    emit_blocking_rename \
                        "BoolPredicateNoArgMethod" \
                        "$method_name() -> var $method_name: Bool" \
                        "No-parameter predicate Bool checks must be properties in strict scope." \
                        "$file:$line_number declaration '$line_text'"
                fi
            fi

        else
            if [[ "$line_text" == *"func "* && "$line_text" == *"()"* && "$line_text" == *"->"* && "$line_text" == *"Bool"* ]] \
                && [[ "$line_text" =~ ^[[:space:]]*(public|open|internal|private|fileprivate)?[[:space:]]*func[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\) ]]; then
                method_name="${BASH_REMATCH[2]}"
                if is_predicate_method_name "$method_name"; then
                    emit_advisory \
                        "BoolPredicateNoArgMethod" \
                        "$method_name" \
                        "Prefer 'var $method_name: Bool'" \
                        "Facade scope keeps this rule as advisory." \
                        "$file:$line_number declaration '$line_text'"
                fi
            fi
        fi
    done < <(nl -ba "$file")
done <<< "$changed_files"

{
    echo "Summary"
    echo "Blocking: $blocking_count"
    echo "Advisory: $advisory_count"
} >> "$report_file"

if (( blocking_count > 0 )); then
    echo "Naming audit failed with $blocking_count blocking violation(s). See $report_file"
    exit 1
fi

echo "Naming audit passed with $advisory_count advisory finding(s). See $report_file"
