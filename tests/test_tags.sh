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

test_tag_create() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "Tagged"
    assert_contains "$ASB_LAST_OUTPUT" "v1.0"

    # Verify tag exists in git
    local backup_dir="${ASB_BACKUP_ROOT}/.claude"
    local tags
    tags=$(git -C "$backup_dir" tag -l 2>/dev/null)
    assert_contains "$tags" "v1.0"
}

test_tag_create_requires_backup() {
    run_asb tag claude v1.0
    if [[ "$ASB_LAST_STATUS" -eq 0 ]]; then
        echo "Expected failure when no backup exists" >&2
        return 1
    fi
}

test_tag_list() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude v2.0
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "v1.0"
    assert_contains "$ASB_LAST_OUTPUT" "v2.0"
}

test_tag_list_empty() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "No tags"
}

test_tag_delete() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb --force tag claude --delete v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "Deleted"

    # Verify tag is gone
    local backup_dir="${ASB_BACKUP_ROOT}/.claude"
    local tags
    tags=$(git -C "$backup_dir" tag -l 2>/dev/null)
    if echo "$tags" | grep -q "v1.0"; then
        echo "Tag v1.0 should have been deleted" >&2
        return 1
    fi
}

test_tag_delete_nonexistent() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude --delete nonexistent
    if [[ "$ASB_LAST_STATUS" -eq 0 ]]; then
        echo "Expected failure when deleting nonexistent tag" >&2
        return 1
    fi
}

test_tag_restore() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"

    # Modify the source and backup again
    echo "modified" >> "${HOME}/.claude/settings.json"
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    # Restore from tag
    run_asb --force restore claude v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "tag"

    # Verify file was restored (shouldn't have "modified")
    if grep -q "modified" "${HOME}/.claude/settings.json" 2>/dev/null; then
        echo "File should have been restored to pre-modification state" >&2
        return 1
    fi
}

test_tag_json_list() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb tag claude v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb --json tag claude --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_json_valid "$ASB_LAST_OUTPUT"
    assert_contains "$ASB_LAST_OUTPUT" "\"tags\""
    assert_contains "$ASB_LAST_OUTPUT" "\"v1.0\""
}

test_tag_json_create() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb --json tag claude v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_json_valid "$ASB_LAST_OUTPUT"
    assert_contains "$ASB_LAST_OUTPUT" "\"success\":true"
    assert_contains "$ASB_LAST_OUTPUT" "\"tag\":\"v1.0\""
}

test_tag_validation() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    # Tag with spaces should fail
    run_asb tag claude "bad tag"
    if [[ "$ASB_LAST_STATUS" -eq 0 ]]; then
        echo "Expected failure for tag with spaces" >&2
        return 1
    fi

    # Tag starting with - should fail
    run_asb tag claude "-badtag"
    if [[ "$ASB_LAST_STATUS" -eq 0 ]]; then
        echo "Expected failure for tag starting with dash" >&2
        return 1
    fi

    # Tag starting with . should fail
    run_asb tag claude ".badtag"
    if [[ "$ASB_LAST_STATUS" -eq 0 ]]; then
        echo "Expected failure for tag starting with dot" >&2
        return 1
    fi

    # Valid semver tag should work
    run_asb tag claude v1.2.3
    assert_exit_code 0 "$ASB_LAST_STATUS"
}

test_tag_dryrun() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb --dry-run tag claude v1.0
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "Would tag"

    # Verify tag was NOT created
    local backup_dir="${ASB_BACKUP_ROOT}/.claude"
    local tags
    tags=$(git -C "$backup_dir" tag -l 2>/dev/null)
    if echo "$tags" | grep -q "v1.0"; then
        echo "Dry-run should not have created tag" >&2
        return 1
    fi
}

run_test "tag_create" test_tag_create || exit 1
run_test "tag_create_requires_backup" test_tag_create_requires_backup || exit 1
run_test "tag_list" test_tag_list || exit 1
run_test "tag_list_empty" test_tag_list_empty || exit 1
run_test "tag_delete" test_tag_delete || exit 1
run_test "tag_delete_nonexistent" test_tag_delete_nonexistent || exit 1
run_test "tag_restore" test_tag_restore || exit 1
run_test "tag_json_list" test_tag_json_list || exit 1
run_test "tag_json_create" test_tag_json_create || exit 1
run_test "tag_validation" test_tag_validation || exit 1
run_test "tag_dryrun" test_tag_dryrun || exit 1

exit 0
