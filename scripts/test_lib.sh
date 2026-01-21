#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
ASB_BIN="$PROJECT_ROOT/asb"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_status() {
    local status="$1"
    local expected="$2"
    local message="$3"
    if [[ "$status" -ne "$expected" ]]; then
        fail "$message (status=$status, expected=$expected)"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        fail "$message"
    fi
}

assert_file_contains() {
    local path="$1"
    local needle="$2"
    local message="$3"
    if [[ ! -f "$path" ]]; then
        fail "Expected file not found: $path"
    fi
    if ! grep -qF "$needle" "$path"; then
        fail "$message"
    fi
}

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        fail "Expected file to exist: $path"
    fi
}

assert_dir_exists() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        fail "Expected directory to exist: $path"
    fi
}

assert_dir_not_exists() {
    local path="$1"
    if [[ -d "$path" ]]; then
        fail "Expected directory to NOT exist: $path"
    fi
}

setup_test_env() {
    local base_dir="$PROJECT_ROOT/.tmp"
    mkdir -p "$base_dir"
    TEST_ROOT=$(mktemp -d -p "$base_dir")
    export HOME="$TEST_ROOT/home"
    mkdir -p "$HOME"

    export TMPDIR="$TEST_ROOT/tmp"
    mkdir -p "$TMPDIR"

    export XDG_CONFIG_HOME="$HOME/.config"
    export ASB_BACKUP_ROOT="$TEST_ROOT/backups"

    export GIT_AUTHOR_NAME="ASB Test"
    export GIT_AUTHOR_EMAIL="asb-test@example.com"
    export GIT_COMMITTER_NAME="ASB Test"
    export GIT_COMMITTER_EMAIL="asb-test@example.com"
}

cleanup_test_env() {
    rm -rf "$TEST_ROOT"
}

create_agent_dir() {
    local agent="$1"
    mkdir -p "$HOME/.${agent}"
}

write_file() {
    local path="$1"
    local content="$2"
    mkdir -p "$(dirname "$path")"
    printf '%s' "$content" > "$path"
}

run_asb() {
    "$ASB_BIN" "$@" 2>&1
}
