#!/usr/bin/env bash
#
# Unit Test Harness for asb
# Sources the asb script without executing main(), making all functions available for testing
#

set -uo pipefail

HARNESS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${HARNESS_DIR}/../.." && pwd)
LIB_DIR="${HARNESS_DIR}/../lib"

# Source test utilities
source "${LIB_DIR}/logging.sh"
source "${LIB_DIR}/assertions.sh"
source "${LIB_DIR}/test_utils.sh"

# Prevent main() from running when we source asb
export ASB_SOURCED=true

# Source the main asb script - all functions now available
source "${REPO_ROOT}/asb"

# Unit test tracking
UNIT_TESTS_PASSED=0
UNIT_TESTS_FAILED=0
UNIT_TESTS_SKIPPED=0
UNIT_FAILED_TESTS=()

# Run a unit test function
run_unit_test() {
    local test_name="$1"
    local func="$2"

    set_current_test "$test_name"

    # Set up isolated test environment
    setup_test_env

    local result=0
    if ( set -euo pipefail; "$func" ); then
        log_pass "$test_name"
        ((UNIT_TESTS_PASSED++))
    else
        result=$?
        if [[ $result -eq 2 ]]; then
            log_skip "$test_name"
            ((UNIT_TESTS_SKIPPED++))
        else
            log_fail "$test_name"
            UNIT_FAILED_TESTS+=("$test_name")
            ((UNIT_TESTS_FAILED++))
        fi
    fi

    teardown_test_env
    clear_current_test
    return 0  # Don't fail the whole suite on one test failure
}

# Print unit test summary
unit_test_summary() {
    local total=$((UNIT_TESTS_PASSED + UNIT_TESTS_FAILED + UNIT_TESTS_SKIPPED))

    echo ""
    echo "===================================="
    echo "Unit Test Results"
    echo "===================================="
    echo "Total:    $total"
    echo "Passed:   $UNIT_TESTS_PASSED"
    echo "Failed:   $UNIT_TESTS_FAILED"
    echo "Skipped:  $UNIT_TESTS_SKIPPED"
    echo "===================================="

    if [[ ${#UNIT_FAILED_TESTS[@]} -gt 0 ]]; then
        echo ""
        echo "Failed Tests:"
        for test in "${UNIT_FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
    fi

    if [[ $UNIT_TESTS_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Helper to capture function output
capture_output() {
    local func="$1"
    shift
    "$func" "$@" 2>&1
}

# Helper to capture only stdout
capture_stdout() {
    local func="$1"
    shift
    "$func" "$@" 2>/dev/null
}

# Helper to capture only stderr
capture_stderr() {
    local func="$1"
    shift
    "$func" "$@" 2>&1 >/dev/null
}

# Helper to get function exit code without output
get_exit_code() {
    local func="$1"
    shift
    "$func" "$@" >/dev/null 2>&1
    echo $?
}

# Helper to assert function succeeds
assert_function_succeeds() {
    local func="$1"
    shift
    if ! "$func" "$@" >/dev/null 2>&1; then
        echo "Expected $func to succeed, but it failed" >&2
        return 1
    fi
}

# Helper to assert function fails
assert_function_fails() {
    local func="$1"
    shift
    if "$func" "$@" >/dev/null 2>&1; then
        echo "Expected $func to fail, but it succeeded" >&2
        return 1
    fi
}

# Helper to create a temporary git repo
create_temp_git_repo() {
    local dir="${1:-$(mktemp -d)}"
    mkdir -p "$dir"
    (
        cd "$dir"
        git init --initial-branch=main >/dev/null 2>&1 || git init >/dev/null 2>&1
        git config user.email "test@test.com"
        git config user.name "Test"
        echo "test" > test.txt
        git add .
        git commit -m "Initial commit" >/dev/null 2>&1
    )
    echo "$dir"
}

# Helper to verify asb functions are available
verify_harness() {
    local required_functions=(
        "log_info"
        "log_error"
        "backup_agent"
        "restore_agent"
        "agent_exists"
        "init_git_repo"
        "create_backup_commit"
        "json_escape_string"
        "load_config"
        "scan_for_agents"
    )

    local missing=()
    for func in "${required_functions[@]}"; do
        if ! declare -F "$func" >/dev/null 2>&1; then
            missing+=("$func")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing functions after sourcing asb:" >&2
        printf '  %s\n' "${missing[@]}" >&2
        return 1
    fi

    echo "Harness verified: ${#required_functions[@]} functions available"
    return 0
}

# Export functions for use in test files
export -f run_unit_test
export -f unit_test_summary
export -f capture_output
export -f capture_stdout
export -f capture_stderr
export -f get_exit_code
export -f assert_function_succeeds
export -f assert_function_fails
export -f create_temp_git_repo
export -f verify_harness
