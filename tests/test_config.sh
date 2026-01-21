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

test_config_init_creates_file() {
    run_asb config init
    assert_exit_code 0 "$ASB_LAST_STATUS"

    local config_file="${XDG_CONFIG_HOME}/asb/config"
    assert_file_exists "$config_file"
    assert_contains "$(cat "$config_file")" "ASB_BACKUP_ROOT"
}

test_config_init_idempotent() {
    local config_file="${XDG_CONFIG_HOME}/asb/config"
    mkdir -p "$(dirname "$config_file")"
    printf "ASB_BACKUP_ROOT=\"/custom\"\n" > "$config_file"
    local before
    before=$(sha256sum "$config_file" | awk '{print $1}')

    run_asb config init
    assert_exit_code 0 "$ASB_LAST_STATUS"

    local after
    after=$(sha256sum "$config_file" | awk '{print $1}')
    assert_equals "$before" "$after"
}

test_config_show_displays_all() {
    local config_file="${XDG_CONFIG_HOME}/asb/config"
    mkdir -p "$(dirname "$config_file")"
    cat > "$config_file" <<'CFG'
ASB_BACKUP_ROOT="/tmp/asb-backups"
ASB_AUTO_COMMIT=false
ASB_VERBOSE=true
CFG

    run_asb config show
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "ASB_BACKUP_ROOT:"
    assert_contains "$ASB_LAST_OUTPUT" "/tmp/asb-backups"
    assert_contains "$ASB_LAST_OUTPUT" "ASB_AUTO_COMMIT:"
    assert_contains "$ASB_LAST_OUTPUT" "false"
    assert_contains "$ASB_LAST_OUTPUT" "ASB_VERBOSE:"
    assert_contains "$ASB_LAST_OUTPUT" "true"
}

test_config_precedence() {
    export ASB_BACKUP_ROOT="/env-backups"
    local config_file="${XDG_CONFIG_HOME}/asb/config"
    mkdir -p "$(dirname "$config_file")"
    printf "ASB_BACKUP_ROOT=\"/config-backups\"\n" > "$config_file"

    run_asb config show
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "/config-backups"
    if [[ "$ASB_LAST_OUTPUT" == *"/env-backups"* ]]; then
        echo "Config did not override environment variable" >&2
        return 1
    fi
}

test_missing_config_graceful() {
    create_claude_fixture
    run_asb --dry-run backup claude
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "DRY RUN"
}

test_xdg_config_home_respected() {
    run_asb config init
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_file_exists "${XDG_CONFIG_HOME}/asb/config"
}

test_malformed_config_error() {
    local config_file="${XDG_CONFIG_HOME}/asb/config"
    mkdir -p "$(dirname "$config_file")"
    printf "ASB_BACKUP_ROOT=\"/tmp\"\\nthis is not valid bash\\n" > "$config_file"

    run_asb config show
    if [[ $ASB_LAST_STATUS -eq 0 ]]; then
        echo "Expected non-zero status for malformed config" >&2
        return 1
    fi
}

run_test "config_init_creates_file" test_config_init_creates_file || exit 1
run_test "config_init_idempotent" test_config_init_idempotent || exit 1
run_test "config_show_displays_all" test_config_show_displays_all || exit 1
run_test "config_precedence" test_config_precedence || exit 1
run_test "missing_config_graceful" test_missing_config_graceful || exit 1
run_test "xdg_config_home_respected" test_xdg_config_home_respected || exit 1
run_test "malformed_config_error" test_malformed_config_error || exit 1

exit 0
