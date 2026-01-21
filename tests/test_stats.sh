#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="${SCRIPT_DIR}/lib"
if [[ "$SCRIPT_DIR" == */lib ]]; then
    LIB_DIR="$SCRIPT_DIR"
fi

source "${LIB_DIR}/logging.sh"
source "${LIB_DIR}/assertions.sh"
source "${LIB_DIR}/test_utils.sh"
source "${LIB_DIR}/fixtures.sh"

declare -F create_claude_fixture >/dev/null 2>&1 || { echo "create_claude_fixture not loaded" >&2; exit 1; }

assert_json_valid() {
    local input="$1"
    skip_if_missing python3 "python3 required for JSON tests" || return $?
    echo "$input" | python3 -c 'import json, sys; json.load(sys.stdin)'
}

test_stats_all_with_backups() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb stats
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "claude"
    assert_contains "$ASB_LAST_OUTPUT" "1"  # At least 1 commit
}

test_stats_all_no_backups() {
    run_asb stats
    assert_exit_code 0 "$ASB_LAST_STATUS"
    # Should still work, just showing no backups or 0 commits
}

test_stats_single_agent() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb stats claude
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "Claude"
    assert_contains "$ASB_LAST_OUTPUT" "backups"
    assert_contains "$ASB_LAST_OUTPUT" "Storage"
}

test_stats_agent_no_backup() {
    run_asb stats claude
    # Should fail or show no backup
    if [[ "$ASB_LAST_STATUS" -eq 0 ]]; then
        # If it succeeds, it should indicate no backup
        assert_contains "$ASB_LAST_OUTPUT" "No backup"
    fi
}

test_stats_json_all() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb --json stats
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_json_valid "$ASB_LAST_OUTPUT"
    assert_contains "$ASB_LAST_OUTPUT" "\"agents\""
}

test_stats_json_single() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb --json stats claude
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_json_valid "$ASB_LAST_OUTPUT"
    assert_contains "$ASB_LAST_OUTPUT" "\"agent\":\"claude\""
    assert_contains "$ASB_LAST_OUTPUT" "\"total_backups\""
    assert_contains "$ASB_LAST_OUTPUT" "\"storage\""
}

test_stats_multiple_commits() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    # Modify and backup again
    echo "change1" >> "${HOME}/.claude/settings.json"
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    # Third backup
    echo "change2" >> "${HOME}/.claude/settings.json"
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb --json stats claude
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_json_valid "$ASB_LAST_OUTPUT"

    # Check that total_backups count is at least 3
    local backups
    backups=$(echo "$ASB_LAST_OUTPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("total_backups",0))' 2>/dev/null)
    if [[ "$backups" -lt 3 ]]; then
        echo "Expected at least 3 backups, got $backups" >&2
        return 1
    fi
}

test_stats_unknown_agent() {
    run_asb stats unknownagent
    if [[ "$ASB_LAST_STATUS" -eq 0 ]]; then
        echo "Expected failure for unknown agent" >&2
        return 1
    fi
}

run_test "stats_all_with_backups" test_stats_all_with_backups || exit 1
run_test "stats_all_no_backups" test_stats_all_no_backups || exit 1
run_test "stats_single_agent" test_stats_single_agent || exit 1
run_test "stats_agent_no_backup" test_stats_agent_no_backup || exit 1
run_test "stats_json_all" test_stats_json_all || exit 1
run_test "stats_json_single" test_stats_json_single || exit 1
run_test "stats_multiple_commits" test_stats_multiple_commits || exit 1
run_test "stats_unknown_agent" test_stats_unknown_agent || exit 1

exit 0
