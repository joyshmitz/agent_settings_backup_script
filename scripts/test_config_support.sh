#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./test_lib.sh
source "$SCRIPT_DIR/test_lib.sh"

setup_test_env
trap cleanup_test_env EXIT

config_dir="$XDG_CONFIG_HOME/asb"
mkdir -p "$config_dir"

custom_root="$TEST_ROOT/custom_backups"
cat > "$config_dir/config" << CONFIGEOF
ASB_BACKUP_ROOT="$custom_root"
ASB_VERBOSE=false
CONFIGEOF

output=$(run_asb init)
status=$?
assert_status "$status" 0 "asb init failed"
assert_dir_exists "$custom_root"

output=$(run_asb config show)
status=$?
assert_status "$status" 0 "asb config show failed"
assert_contains "$output" "$custom_root" "config show did not reflect custom backup root"
