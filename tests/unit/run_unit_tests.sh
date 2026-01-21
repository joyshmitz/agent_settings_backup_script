#!/usr/bin/env bash
#
# Unit Test Runner
# Runs all unit tests in the tests/unit directory
#

set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Source the harness
source "${SCRIPT_DIR}/harness.sh"

echo "============================================"
echo "  ASB Unit Test Suite"
echo "============================================"
echo ""

# Verify harness is working
if ! verify_harness; then
    echo "ERROR: Harness verification failed" >&2
    exit 1
fi
echo ""

# Find and run all unit test files
shopt -s nullglob
test_files=("${SCRIPT_DIR}"/test_*.sh)
shopt -u nullglob

if [[ ${#test_files[@]} -eq 0 ]]; then
    echo "No unit test files found in ${SCRIPT_DIR}"
    echo "Create test files matching pattern: test_*.sh"
    exit 0
fi

echo "Found ${#test_files[@]} test file(s)"
echo ""

for test_file in "${test_files[@]}"; do
    test_name=$(basename "$test_file" .sh)
    log_section "Running: $test_name"

    # Source the test file (it should call run_unit_test for each test)
    source "$test_file"
done

# Print summary
unit_test_summary
exit $?
