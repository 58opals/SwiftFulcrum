#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

report_file=".build/reports/naming-audit.txt"
mkdir -p "$(dirname "$report_file")"

changed_files="$({
    git diff --name-only --diff-filter=ACMR
    git diff --cached --name-only --diff-filter=ACMR
    git ls-files --others --exclude-standard
} | rg '\.swift$' | LC_ALL=C sort -u || true)"

blocking_count=0
advisory_count=0

disallowed_suffixes=(Factory Service ViewModel Store DataSource Mapper Formatter Manager Handler Helper Provider)
preferred_role_suffixes=(View Model Presenter Interactor Data State Router Client Repository Validator Policy Intent Effect Error Request Response Configuration Actor Coordinator Parser Encoder Decoder Adapter Cache Facade)
predicate_prefixes=(is has can should supports allows requires needs wants may must)
bool_no_arg_regex='\\([[:space:]]*\\)[[:space:]]*->[[:space:]]*Bool'

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

last_component() {
    local name="$1"
    echo "${name##*.}"
}

trailing_role_token() {
    local name="$1"
    local leaf
    local token
    leaf="$(last_component "$name")"
    for token in "${preferred_role_suffixes[@]}" "${disallowed_suffixes[@]}"; do
        if [[ "$leaf" == *"$token" ]]; then
            echo "$token"
            return 0
        fi
    done
    echo ""
}

is_facade_scope_file() {
    local file="$1"
    if rg -q '^[[:space:]]*(public|open)[[:space:]]+extension[[:space:]]+SwiftFulcrum(\.|$)' "$file"; then
        return 0
    fi
    if rg -q '^[[:space:]]*(public|open)[[:space:]]+(actor|class|struct|enum|protocol|typealias)[[:space:]]+SwiftFulcrum(\.|$)' "$file"; then
        return 0
    fi
    if rg -q '^[[:space:]]*extension[[:space:]]+SwiftFulcrum(\.|$)' "$file"; then
        return 0
    fi
    return 1
}

primary_declaration_target() {
    local file="$1"
    local line
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*(public|open)?[[:space:]]*extension[[:space:]]+([A-Za-z_][A-Za-z0-9_\.]*) ]]; then
            echo "${BASH_REMATCH[2]}"
            return 0
        fi
        if [[ "$line" =~ ^[[:space:]]*(public|open)[[:space:]]+(actor|class|struct|enum|protocol|typealias)[[:space:]]+([A-Za-z_][A-Za-z0-9_\.]*) ]]; then
            echo "${BASH_REMATCH[3]}"
            return 0
        fi
    done < "$file"
    echo ""
}

cat > "$report_file" <<EOF_REPORT
# Swift Naming Audit
Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)

EOF_REPORT

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
    if is_facade_scope_file "$file"; then
        scope="Facade"
    fi

    if [[ "$scope" == "Strict" ]]; then
        base_name="$(basename "$file" .swift)"
        primary_target="$(primary_declaration_target "$file")"
        if [[ -n "$primary_target" ]]; then
            if [[ "$base_name" != "$primary_target"* ]]; then
                emit_blocking_nonrename \
                    "FilenameDeclarationMismatch" \
                    "Strict-scope file names must map unambiguously to their primary declaration target." \
                    "Rename file to start with '$primary_target'." \
                    "$file"
            fi
        fi
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
                        "Facade extension targets must remain within SwiftFulcrum namespace chain." \
                        "Move declaration under SwiftFulcrum.* or make it non-public." \
                        "$file:$line_number declaration '$line_text'"
                fi
            fi
        fi

        if [[ "$line_text" =~ ^[[:space:]]*(public|open)[[:space:]]+(actor|class|struct|enum|protocol|typealias)[[:space:]]+([A-Za-z_][A-Za-z0-9_\.]*) ]]; then
            declared_name="${BASH_REMATCH[3]}"
            declared_leaf="$(last_component "$declared_name")"

            for suffix in "${disallowed_suffixes[@]}"; do
                if [[ "$declared_leaf" == *"$suffix" ]]; then
                    renamed_leaf="${declared_leaf%$suffix}"
                    if [[ -n "$renamed_leaf" && "$renamed_leaf" != "$declared_leaf" ]]; then
                        emit_blocking_rename \
                            "DisallowedRoleSuffix" \
                            "$declared_leaf -> $renamed_leaf" \
                            "Disallowed role suffix '$suffix' is blocking for new or renamed symbols." \
                            "$file:$line_number declaration '$line_text'"
                    else
                        emit_blocking_nonrename \
                            "DisallowedRoleSuffix" \
                            "Disallowed role suffix '$suffix' is blocking for new or renamed symbols." \
                            "Rename this symbol to remove disallowed role suffixes." \
                            "$file:$line_number declaration '$line_text'"
                    fi
                fi
            done

            if [[ "$declared_name" == *.* ]]; then
                parent_name="${declared_name%.*}"
                parent_leaf="$(last_component "$parent_name")"
                child_role="$(trailing_role_token "$declared_leaf")"
                parent_role="$(trailing_role_token "$parent_leaf")"
                if [[ -n "$child_role" && "$child_role" == "$parent_role" ]]; then
                    stripped_leaf="${declared_leaf%$child_role}"
                    if [[ -n "$stripped_leaf" && "$stripped_leaf" != "$declared_leaf" ]]; then
                        emit_blocking_rename \
                            "DuplicateRoleSuffix" \
                            "$declared_name -> ${parent_name}.${stripped_leaf}" \
                            "Child declaration duplicates ancestor role suffix '$child_role'." \
                            "$file:$line_number declaration '$line_text'"
                    else
                        emit_blocking_nonrename \
                            "DuplicateRoleSuffix" \
                            "Child declaration duplicates ancestor role suffix '$child_role'." \
                            "Rename child declaration to remove repeated role suffix." \
                            "$file:$line_number declaration '$line_text'"
                    fi
                fi
            fi
        fi

        if [[ "$line_text" =~ ^[[:space:]]*(public|open|internal|private|fileprivate)?[[:space:]]*func[[:space:]]+([A-Za-z_][A-Za-z0-9_]*) ]]; then
            method_name="${BASH_REMATCH[2]}"
            if [[ "$method_name" =~ ^(get|set)[A-Z] ]]; then
                emit_blocking_nonrename \
                    "GetSetPrefix" \
                    "get/set method prefixes are not allowed." \
                    "Rename method without get/set prefix." \
                    "$file:$line_number declaration '$line_text'"
            fi

            if [[ "$line_text" =~ $bool_no_arg_regex ]]; then
                if is_predicate_method_name "$method_name"; then
                    if [[ "$scope" == "Strict" ]]; then
                        emit_blocking_rename \
                            "BoolPredicateNoArgMethod" \
                            "$method_name() -> var $method_name: Bool" \
                            "No-parameter predicate Bool checks must be properties in strict scope." \
                            "$file:$line_number declaration '$line_text'"
                    else
                        emit_advisory \
                            "BoolPredicateNoArgMethod" \
                            "$method_name" \
                            "Prefer 'var $method_name: Bool'" \
                            "Facade scope keeps this rule as advisory." \
                            "$file:$line_number declaration '$line_text'"
                    fi
                fi
            fi
        fi

        if [[ "$line_text" =~ ^[[:space:]]*(public|open|internal|private|fileprivate)?[[:space:]]*(var|let)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*) ]]; then
            property_name="${BASH_REMATCH[3]}"
            if [[ "$property_name" =~ ^(get|set)[A-Z] ]]; then
                emit_blocking_nonrename \
                    "GetSetPrefix" \
                    "get/set property prefixes are not allowed." \
                    "Rename property without get/set prefix." \
                    "$file:$line_number declaration '$line_text'"
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
