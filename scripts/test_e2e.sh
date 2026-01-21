#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./test_lib.sh
source "$SCRIPT_DIR/test_lib.sh"

setup_test_env
trap cleanup_test_env EXIT

create_agent_dir "claude"
write_file "$HOME/.claude/settings.json" "v1"

log_file="$TEST_ROOT/e2e.log"

run_asb init >> "$log_file" 2>&1
run_asb backup claude >> "$log_file" 2>&1

write_file "$HOME/.claude/settings.json" "v2"
run_asb diff claude >> "$log_file" 2>&1

run_asb --force restore claude >> "$log_file" 2>&1
content=$(cat "$HOME/.claude/settings.json")
assert_contains "$content" "v1" "restore did not revert settings"

run_asb history claude >> "$log_file" 2>&1
assert_file_exists "$log_file"
assert_file_contains "$log_file" "Backup History" "log missing history output"
