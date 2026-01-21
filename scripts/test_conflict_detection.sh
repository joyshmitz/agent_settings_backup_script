#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./test_lib.sh
source "$SCRIPT_DIR/test_lib.sh"

setup_test_env
trap cleanup_test_env EXIT

create_agent_dir "claude"
write_file "$HOME/.claude/config.json" "v1"
write_file "$HOME/.claude/keep.txt" "keep"

output=$(run_asb backup claude)
status=$?
assert_status "$status" 0 "backup failed"

# Make changes that should appear in preview
write_file "$HOME/.claude/config.json" "v2"
rm -f "$HOME/.claude/keep.txt"
write_file "$HOME/.claude/local-only.txt" "local"

output=$(run_asb --dry-run restore claude)
status=$?
assert_status "$status" 0 "restore preview failed"

assert_contains "$output" "will be DELETED" "preview missing delete indicators"
assert_contains "$output" "will be ADDED" "preview missing add indicators"
assert_contains "$output" "will be REPLACED" "preview missing replace indicators"
