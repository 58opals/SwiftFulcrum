#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
usage() {
    printf '%s\n' 'usage: validate.sh [--list] [develop | focused IDENTIFIER | assurance]' \
        'focused IDENTIFIER matches a literal suite or test-identifier substring.' \
        'OPAL_VALIDATION_SCRATCH_PATH selects a per-repository, toolchain-compatible SwiftPM cache.'
}
list_only=false
if [ "${1:-}" = --help ] || [ "${1:-}" = -h ]; then usage; exit 0; fi
if [ "${1:-}" = --list ]; then list_only=true; shift; fi
lane=${1:-develop}
[ "$#" -eq 0 ] || shift
case "$lane" in
    develop | assurance) [ "$#" -eq 0 ] || { usage >&2; exit 64; } ;;
    focused)
        [ "$#" -eq 1 ] && [ -n "$1" ] || { usage >&2; exit 64; }
        case "$1" in -*|*[[:cntrl:]]*) usage >&2; exit 64 ;; esac
        identifier=$1
        ;;
    *) usage >&2; exit 64 ;;
esac

scratch_path=${OPAL_VALIDATION_SCRATCH_PATH:-"$repo_root/.build/validation"}
temporary=$(mktemp -d "${TMPDIR:-/tmp}/swift-fulcrum-validation.XXXXXX")
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
cd "$repo_root"
git ls-files --error-unmatch -- Package.resolved > /dev/null
cp Package.resolved "$temporary/Package.resolved"
check_lock() {
    cmp -s Package.resolved "$temporary/Package.resolved" || {
        printf '%s\n' 'Package.resolved changed during validation.' >&2; exit 1;
    }
}
# Every lane here is offline, even when the calling shell enables live tests.
export SWIFTFULCRUM_RUN_NETWORK=0 SWIFTFULCRUM_RUN_NETWORK_SLOW=0 SWIFTFULCRUM_RUN_LIVE_SLOW=0

# Discovery performs the only build; execution below reuses this exact lane.
env -u SDKROOT /usr/bin/xcrun swift test --scratch-path "$scratch_path" --force-resolved-versions list > "$temporary/inventory"
check_lock
grep -E '^SwiftFulcrumLocalTests[./]' "$temporary/inventory" > "$temporary/offline-inventory" || {
    printf '%s\n' 'No local test definitions were discovered.' >&2; exit 65;
}
if [ "$lane" = focused ]; then
    grep -F -- "$identifier" "$temporary/offline-inventory" > "$temporary/selection" || {
        printf '%s\n' 'No test identifiers match the requested literal substring.' >&2; exit 65;
    }
    # Exact discovered local identifiers prevent a shared name selecting a live suite.
    # SwiftPM appends its own parameter matching; an end anchor can execute zero tests.
    filter="^($(sed 's/[][\\.^$*+?(){}|]/\\&/g' "$temporary/selection" | paste -sd '|' -))"
elif [ "$lane" = develop ]; then
    filter='^SwiftFulcrumLocalTests[./](ClientConfigurationValidator|ProtocolNegotiationConfigurationValidator|ProtocolNegotiationGenerationValidator|ResponseDecodingValidator|OpalDiagnosticsSwiftFulcrumValidator)[./]'
    grep -E -- "$filter" "$temporary/offline-inventory" > "$temporary/selection" || {
        printf '%s\n' 'The development selection matched no discovered tests.' >&2; exit 65;
    }
else
    filter='^SwiftFulcrumLocalTests[./]'
    cp "$temporary/offline-inventory" "$temporary/selection"
fi
selected=$(awk 'NF { count++ } END { print count+0 }' "$temporary/selection")
total=$(awk 'NF { count++ } END { print count+0 }' "$temporary/inventory")
[ "$selected" -gt 0 ] || { printf '%s\n' 'Test discovery returned no tests.' >&2; exit 65; }
printf 'SwiftFulcrum %s (offline): %s/%s discovered test definitions selected.\n' "$lane" "$selected" "$total"
printf '%s\n' 'Development/focused results do not replace complete local assurance; live tests remain separately opt-in.'
if "$list_only"; then cat "$temporary/selection"; exit 0; fi
status=0
env -u SDKROOT /usr/bin/xcrun swift test --scratch-path "$scratch_path" --force-resolved-versions --skip-build --filter "$filter" --xunit-output "$temporary/results.xml" || status=$?
check_lock
[ "$status" -eq 0 ] || exit "$status"
executed=0
for result in "$temporary"/results*.xml; do
    [ -f "$result" ] || continue
    count=$(/usr/bin/xmllint --nonet --xpath 'count(//testcase[not(skipped)])' "$result")
    case "$count" in ''|*[!0-9]*) printf '%s\n' 'Invalid test execution count.' >&2; exit 65 ;; esac
    executed=$((executed + count))
done
[ "$executed" -gt 0 ] || { printf '%s\n' 'No non-skipped tests executed.' >&2; exit 65; }
printf 'Executed %s non-skipped test definitions.\n' "$executed"
exit "$status"
