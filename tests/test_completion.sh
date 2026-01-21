#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/logging.sh"
source "${LIB_DIR}/assertions.sh"
source "${LIB_DIR}/test_utils.sh"
source "${LIB_DIR}/fixtures.sh"

test_bash_completion_valid() {
    run_asb completion bash
    assert_exit_code 0 "$ASB_LAST_STATUS"

    local temp_script
    temp_script=$(mktemp)
    echo "$ASB_LAST_OUTPUT" > "$temp_script"

    if ! bash -n "$temp_script" 2>/dev/null; then
        echo "Bash completion script has syntax errors" >&2
        rm -f "$temp_script"
        return 1
    fi

    rm -f "$temp_script"
    assert_contains "$ASB_LAST_OUTPUT" "_asb_completions"
    assert_contains "$ASB_LAST_OUTPUT" "complete -F"
}

test_zsh_completion_valid() {
    skip_if_missing zsh "zsh not available"

    run_asb completion zsh
    assert_exit_code 0 "$ASB_LAST_STATUS"

    assert_contains "$ASB_LAST_OUTPUT" "#compdef asb"
    assert_contains "$ASB_LAST_OUTPUT" "_asb"
    assert_contains "$ASB_LAST_OUTPUT" "_arguments"
}

test_fish_completion_valid() {
    skip_if_missing fish "fish not available"

    run_asb completion fish
    assert_exit_code 0 "$ASB_LAST_STATUS"

    assert_contains "$ASB_LAST_OUTPUT" "complete -c asb"
    assert_contains "$ASB_LAST_OUTPUT" "backup"
    assert_contains "$ASB_LAST_OUTPUT" "restore"
}

test_bash_completion_commands() {
    run_asb completion bash
    assert_exit_code 0 "$ASB_LAST_STATUS"

    assert_contains "$ASB_LAST_OUTPUT" "backup"
    assert_contains "$ASB_LAST_OUTPUT" "restore"
    assert_contains "$ASB_LAST_OUTPUT" "export"
    assert_contains "$ASB_LAST_OUTPUT" "import"
    assert_contains "$ASB_LAST_OUTPUT" "list"
    assert_contains "$ASB_LAST_OUTPUT" "history"
    assert_contains "$ASB_LAST_OUTPUT" "diff"
    assert_contains "$ASB_LAST_OUTPUT" "init"
    assert_contains "$ASB_LAST_OUTPUT" "config"
    assert_contains "$ASB_LAST_OUTPUT" "completion"
}

test_bash_completion_agents() {
    run_asb completion bash
    assert_exit_code 0 "$ASB_LAST_STATUS"

    assert_contains "$ASB_LAST_OUTPUT" "claude"
    assert_contains "$ASB_LAST_OUTPUT" "codex"
    assert_contains "$ASB_LAST_OUTPUT" "cursor"
    assert_contains "$ASB_LAST_OUTPUT" "gemini"
    assert_contains "$ASB_LAST_OUTPUT" "cline"
    assert_contains "$ASB_LAST_OUTPUT" "amp"
    assert_contains "$ASB_LAST_OUTPUT" "aider"
}

test_bash_completion_flags() {
    run_asb completion bash
    assert_exit_code 0 "$ASB_LAST_STATUS"

    assert_contains "$ASB_LAST_OUTPUT" "--dry-run"
    assert_contains "$ASB_LAST_OUTPUT" "--force"
    assert_contains "$ASB_LAST_OUTPUT" "--verbose"
}

test_completion_restore_commits() {
    create_claude_fixture
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    printf "change\n" >> "$HOME/.claude/settings.json"
    run_asb backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"

    run_asb completion bash
    assert_exit_code 0 "$ASB_LAST_STATUS"

    # shellcheck disable=SC1090
    source <(printf "%s" "$ASB_LAST_OUTPUT")

    COMPREPLY=()
    COMP_WORDS=(asb restore claude "")
    COMP_CWORD=3
    _asb_completions

    local latest
    latest=$(git -C "$ASB_BACKUP_ROOT/.claude" log -1 --format=%h 2>/dev/null || true)
    if [[ -z "$latest" ]]; then
        echo "Expected git history in backup for completion test" >&2
        return 1
    fi

    if [[ " ${COMPREPLY[*]} " != *" $latest "* ]]; then
        echo "Expected completion to include latest commit hash" >&2
        echo "COMPREPLY: ${COMPREPLY[*]}" >&2
        return 1
    fi
}

test_zsh_completion_commands() {
    skip_if_missing zsh "zsh not available"

    run_asb completion zsh
    assert_exit_code 0 "$ASB_LAST_STATUS"

    assert_contains "$ASB_LAST_OUTPUT" "'backup:Backup agent settings'"
    assert_contains "$ASB_LAST_OUTPUT" "'restore:Restore agent from backup'"
}

test_fish_completion_commands() {
    skip_if_missing fish "fish not available"

    run_asb completion fish
    assert_exit_code 0 "$ASB_LAST_STATUS"

    assert_contains "$ASB_LAST_OUTPUT" "-a backup -d 'Backup agent settings'"
    assert_contains "$ASB_LAST_OUTPUT" "-a restore -d 'Restore agent from backup'"
}

test_unknown_shell_error() {
    run_asb completion unknown
    assert_exit_code 1 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "Unknown shell"
    assert_contains "$ASB_LAST_OUTPUT" "bash"
    assert_contains "$ASB_LAST_OUTPUT" "zsh"
    assert_contains "$ASB_LAST_OUTPUT" "fish"
}

test_completion_default_bash() {
    run_asb completion
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "_asb_completions"
}

run_test "bash_completion_valid" test_bash_completion_valid || exit 1
run_test "zsh_completion_valid" test_zsh_completion_valid || exit 1
run_test "fish_completion_valid" test_fish_completion_valid || exit 1
run_test "bash_completion_commands" test_bash_completion_commands || exit 1
run_test "bash_completion_agents" test_bash_completion_agents || exit 1
run_test "bash_completion_flags" test_bash_completion_flags || exit 1
run_test "completion_restore_commits" test_completion_restore_commits || exit 1
run_test "zsh_completion_commands" test_zsh_completion_commands || exit 1
run_test "fish_completion_commands" test_fish_completion_commands || exit 1
run_test "unknown_shell_error" test_unknown_shell_error || exit 1
run_test "completion_default_bash" test_completion_default_bash || exit 1

exit 0
