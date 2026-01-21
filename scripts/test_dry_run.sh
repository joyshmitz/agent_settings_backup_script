#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./test_lib.sh
source "$SCRIPT_DIR/test_lib.sh"

setup_test_env
trap cleanup_test_env EXIT

create_agent_dir "claude"
write_file "$HOME/.claude/settings.json" "v1"

output=$(run_asb --dry-run backup claude)
status=$?
assert_status "$status" 0 "dry-run backup failed"
assert_dir_not_exists "$ASB_BACKUP_ROOT/.claude"

output=$(run_asb backup claude)
status=$?
assert_status "$status" 0 "backup failed"

write_file "$HOME/.claude/settings.json" "v2"

output=$(run_asb --dry-run restore claude)
status=$?
assert_status "$status" 0 "dry-run restore failed"

content=$(cat "$HOME/.claude/settings.json")
assert_contains "$content" "v2" "dry-run restore should not modify files"
