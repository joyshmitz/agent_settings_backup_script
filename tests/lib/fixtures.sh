#!/usr/bin/env bash
# Fixture creation helpers

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="$SCRIPT_DIR"
if [[ "$LIB_DIR" != */lib ]]; then
    LIB_DIR="${LIB_DIR}/lib"
fi

if ! declare -F create_mock_agent >/dev/null 2>&1; then
    if [[ -f "${LIB_DIR}/test_utils.sh" ]]; then
        # shellcheck source=tests/lib/test_utils.sh
        source "${LIB_DIR}/test_utils.sh"
    fi
fi

create_claude_fixture() {
    create_mock_agent "claude"
}

create_cursor_fixture() {
    create_mock_agent "cursor"
}

create_codex_fixture() {
    create_mock_agent "codex"
}

export -f create_claude_fixture
export -f create_cursor_fixture
export -f create_codex_fixture
