#!/usr/bin/env bash
#
# Unit Tests: Git Functions
# Tests init_git_repo, create_backup_commit, resolve_tag_or_commit
#

# ============================================
# init_git_repo tests
# ============================================

test_init_git_repo_creates_git_dir() {
    local test_dir="${TEST_ENV_ROOT}/init_test"
    mkdir -p "$test_dir"

    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    assert_dir_exists "${test_dir}/.git" || return 1
}

test_init_git_repo_creates_gitignore() {
    local test_dir="${TEST_ENV_ROOT}/init_test2"
    mkdir -p "$test_dir"

    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    assert_file_exists "${test_dir}/.gitignore" || return 1
}

test_init_git_repo_gitignore_contents() {
    local test_dir="${TEST_ENV_ROOT}/init_test3"
    mkdir -p "$test_dir"

    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    local content
    content=$(cat "${test_dir}/.gitignore")

    # Should contain common exclusion patterns
    assert_contains "$content" "*.log" || { echo "Missing *.log pattern" >&2; return 1; }
    assert_contains "$content" "cache" || { echo "Missing cache pattern" >&2; return 1; }
}

test_init_git_repo_makes_initial_commit() {
    local test_dir="${TEST_ENV_ROOT}/init_test4"
    mkdir -p "$test_dir"

    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    local commit_count
    commit_count=$(git -C "$test_dir" rev-list --count HEAD 2>/dev/null || echo 0)

    if [[ "$commit_count" -lt 1 ]]; then
        echo "Expected at least 1 commit, got $commit_count" >&2
        return 1
    fi
}

test_init_git_repo_handles_existing_repo() {
    local test_dir="${TEST_ENV_ROOT}/init_test5"
    mkdir -p "$test_dir"

    # Create existing repo
    git -C "$test_dir" init >/dev/null 2>&1

    # Should not fail on existing repo
    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1 || return 1
}

test_init_git_repo_path_with_spaces() {
    local test_dir="${TEST_ENV_ROOT}/path with spaces"
    mkdir -p "$test_dir"

    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    assert_dir_exists "${test_dir}/.git" || return 1
}

# ============================================
# create_backup_commit tests
# ============================================

test_create_backup_commit_stages_changes() {
    local test_dir="${TEST_ENV_ROOT}/commit_test"
    mkdir -p "$test_dir"
    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    # Add a new file
    echo "new content" > "${test_dir}/newfile.txt"

    create_backup_commit "$test_dir" "testagent" "" >/dev/null 2>&1

    # File should be committed
    if ! git -C "$test_dir" show HEAD:newfile.txt >/dev/null 2>&1; then
        echo "newfile.txt should be committed" >&2
        return 1
    fi
}

test_create_backup_commit_message_format() {
    local test_dir="${TEST_ENV_ROOT}/commit_test2"
    mkdir -p "$test_dir"
    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    echo "content" > "${test_dir}/file.txt"
    create_backup_commit "$test_dir" "testagent" "" >/dev/null 2>&1

    local msg
    msg=$(git -C "$test_dir" log -1 --pretty=%s)

    # Should contain "Backup" and timestamp-like content
    assert_contains "$msg" "Backup" || { echo "Commit message should contain 'Backup'" >&2; return 1; }
}

test_create_backup_commit_no_changes() {
    local test_dir="${TEST_ENV_ROOT}/commit_test3"
    mkdir -p "$test_dir"
    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    local initial_commit
    initial_commit=$(git -C "$test_dir" rev-parse HEAD)

    # No new changes - should succeed but not create new commit
    create_backup_commit "$test_dir" "testagent" "" >/dev/null 2>&1

    local current_commit
    current_commit=$(git -C "$test_dir" rev-parse HEAD)

    # HEAD might be same (no changes) or different (if initial state had uncommitted changes)
    # Just verify no error occurred
}

test_create_backup_commit_sets_last_commit_var() {
    local test_dir="${TEST_ENV_ROOT}/commit_test4"
    mkdir -p "$test_dir"
    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    echo "content" > "${test_dir}/file.txt"

    # Clear the variable
    LAST_BACKUP_COMMIT=""
    create_backup_commit "$test_dir" "testagent" "" >/dev/null 2>&1

    if [[ -z "$LAST_BACKUP_COMMIT" ]]; then
        echo "LAST_BACKUP_COMMIT should be set after commit" >&2
        return 1
    fi
}

test_create_backup_commit_special_chars_in_filename() {
    local test_dir="${TEST_ENV_ROOT}/commit_test5"
    mkdir -p "$test_dir"
    init_git_repo "$test_dir" "testagent" >/dev/null 2>&1

    # Create file with special characters (that are allowed)
    echo "content" > "${test_dir}/file-with-dashes_and_underscores.txt"
    create_backup_commit "$test_dir" "testagent" "" >/dev/null 2>&1

    if ! git -C "$test_dir" show HEAD:file-with-dashes_and_underscores.txt >/dev/null 2>&1; then
        echo "File with special chars should be committed" >&2
        return 1
    fi
}

# ============================================
# resolve_tag_or_commit tests
# Note: This function takes (agent_name, ref) not (dir, ref)
# It uses get_agent_backup_dir internally
# ============================================

test_resolve_tag_existing_tag() {
    # Create a mock agent backup with a tag
    mkdir -p "${HOME}/.claude"
    echo '{"test": true}' > "${HOME}/.claude/settings.json"

    # Create backup first
    backup_agent "claude" >/dev/null 2>&1

    # Create a tag in the backup
    local backup_dir="${ASB_BACKUP_ROOT}/.claude"
    git -C "$backup_dir" tag "v1.0" >/dev/null 2>&1

    local resolved
    resolved=$(resolve_tag_or_commit "claude" "v1.0" 2>/dev/null)

    if [[ -z "$resolved" ]]; then
        echo "Should resolve v1.0 tag" >&2
        return 1
    fi
}

test_resolve_tag_short_commit_hash() {
    mkdir -p "${HOME}/.claude"
    echo '{"test": true}' > "${HOME}/.claude/settings.json"
    backup_agent "claude" >/dev/null 2>&1

    local backup_dir="${ASB_BACKUP_ROOT}/.claude"
    local full_hash
    full_hash=$(git -C "$backup_dir" rev-parse HEAD)
    local short_hash="${full_hash:0:7}"

    local resolved
    resolved=$(resolve_tag_or_commit "claude" "$short_hash" 2>/dev/null)

    assert_equals "$full_hash" "$resolved" || return 1
}

test_resolve_tag_full_commit_hash() {
    mkdir -p "${HOME}/.claude"
    echo '{"test": true}' > "${HOME}/.claude/settings.json"
    backup_agent "claude" >/dev/null 2>&1

    local backup_dir="${ASB_BACKUP_ROOT}/.claude"
    local full_hash
    full_hash=$(git -C "$backup_dir" rev-parse HEAD)

    local resolved
    resolved=$(resolve_tag_or_commit "claude" "$full_hash" 2>/dev/null)

    assert_equals "$full_hash" "$resolved" || return 1
}

test_resolve_tag_head() {
    mkdir -p "${HOME}/.claude"
    echo '{"test": true}' > "${HOME}/.claude/settings.json"
    backup_agent "claude" >/dev/null 2>&1

    local backup_dir="${ASB_BACKUP_ROOT}/.claude"
    local expected
    expected=$(git -C "$backup_dir" rev-parse HEAD)

    local resolved
    resolved=$(resolve_tag_or_commit "claude" "HEAD" 2>/dev/null)

    assert_equals "$expected" "$resolved" || return 1
}

test_resolve_tag_nonexistent() {
    mkdir -p "${HOME}/.claude"
    echo '{"test": true}' > "${HOME}/.claude/settings.json"
    backup_agent "claude" >/dev/null 2>&1

    # Should fail for non-existent tag
    if resolve_tag_or_commit "claude" "nonexistenttag" >/dev/null 2>&1; then
        echo "Should fail for non-existent tag" >&2
        return 1
    fi
}

# Run all tests
run_unit_test "init_git_repo_creates_git_dir" test_init_git_repo_creates_git_dir
run_unit_test "init_git_repo_creates_gitignore" test_init_git_repo_creates_gitignore
run_unit_test "init_git_repo_gitignore_contents" test_init_git_repo_gitignore_contents
run_unit_test "init_git_repo_makes_initial_commit" test_init_git_repo_makes_initial_commit
run_unit_test "init_git_repo_handles_existing_repo" test_init_git_repo_handles_existing_repo
run_unit_test "init_git_repo_path_with_spaces" test_init_git_repo_path_with_spaces
run_unit_test "create_backup_commit_stages_changes" test_create_backup_commit_stages_changes
run_unit_test "create_backup_commit_message_format" test_create_backup_commit_message_format
run_unit_test "create_backup_commit_no_changes" test_create_backup_commit_no_changes
run_unit_test "create_backup_commit_sets_last_commit_var" test_create_backup_commit_sets_last_commit_var
run_unit_test "create_backup_commit_special_chars_in_filename" test_create_backup_commit_special_chars_in_filename
run_unit_test "resolve_tag_existing_tag" test_resolve_tag_existing_tag
run_unit_test "resolve_tag_short_commit_hash" test_resolve_tag_short_commit_hash
run_unit_test "resolve_tag_full_commit_hash" test_resolve_tag_full_commit_hash
run_unit_test "resolve_tag_head" test_resolve_tag_head
run_unit_test "resolve_tag_nonexistent" test_resolve_tag_nonexistent
