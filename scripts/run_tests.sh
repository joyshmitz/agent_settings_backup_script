#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

tests=(
    test_config_support.sh
    test_dry_run.sh
    test_conflict_detection.sh
    test_e2e.sh
)

for test in "${tests[@]}"; do
    printf 'Running %s...\n' "$test"
    if "$SCRIPT_DIR/$test"; then
        printf 'PASS: %s\n' "$test"
    else
        printf 'FAIL: %s\n' "$test" >&2
        exit 1
    fi
    printf '\n'
done

printf 'All tests passed.\n'
