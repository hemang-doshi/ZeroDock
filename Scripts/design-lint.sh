#!/bin/bash
# Enforces docs/design-system.md: views take sizes from DockLayout and DockType, never raw numbers.
set -euo pipefail
cd "$(dirname "$0")/.."
status=0
check() {
    local message="$1" pattern="$2"
    local hits
    hits=$(grep -rnE "$pattern" Features Components App --include='*.swift' || true)
    if [[ -n "$hits" ]]; then
        echo "design-lint: $message" >&2
        echo "$hits" >&2
        status=1
    fi
}
check 'raw font size; use DockType' '\.font\(\.system\(size:'
check 'raw padding number; use DockLayout' '\.padding\([^)]*[1-9]'
check 'raw corner radius; use DockLayout.radius / innerRadius' 'cornerRadius: *[0-9]'
check 'raw stack spacing number; use DockLayout.gap / tight / pad' '(HStack|VStack)\([^)]*spacing: *[1-9]'
if [[ $status -eq 0 ]]; then echo "design-lint: ok"; fi
exit $status
