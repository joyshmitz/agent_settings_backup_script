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

assert_json_valid() {
    local input="$1"
    skip_if_missing python3 "python3 required for JSON tests" || return $?
    echo "$input" | python3 -c 'import json, sys; json.load(sys.stdin)'
}

# Create a mock agent folder for discovery tests
create_discovery_agent() {
    local folder="$1"
    local dest="${HOME}/${folder}"
    mkdir -p "$dest"
    echo '{"mock": true}' > "$dest/settings.json"
}

test_discover_list_finds_agents() {
    # Create a discoverable agent (.kodu is in DISCOVERY_PATTERNS)
    create_discovery_agent ".kodu"

    run_asb discover --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" ".kodu"
    assert_contains "$ASB_LAST_OUTPUT" "Kodu"
}

test_discover_list_no_new_agents() {
    # Only has known agents (create_claude_fixture), nothing discoverable
    run_asb discover --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "No new agents"
}

test_discover_auto_adds_agents() {
    create_discovery_agent ".kodu"

    run_asb discover --auto
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "Added"
    assert_contains "$ASB_LAST_OUTPUT" "Kodu"

    # Verify agent was added - should now appear in list
    run_asb list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "kodu"
}

test_discover_json_list() {
    create_discovery_agent ".kodu"

    run_asb --json discover --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_json_valid "$ASB_LAST_OUTPUT"
    assert_contains "$ASB_LAST_OUTPUT" "\"discovered\""
    assert_contains "$ASB_LAST_OUTPUT" "\"kodu\""
    assert_contains "$ASB_LAST_OUTPUT" "\"Kodu\""
}

test_discover_json_auto() {
    create_discovery_agent ".kodu"

    run_asb --json discover --auto
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_json_valid "$ASB_LAST_OUTPUT"
    assert_contains "$ASB_LAST_OUTPUT" "\"added\""
}

test_discover_multiple_agents() {
    create_discovery_agent ".kodu"
    create_discovery_agent ".continue"
    create_discovery_agent ".tabby"

    run_asb --json discover --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_json_valid "$ASB_LAST_OUTPUT"

    # Count discovered agents
    local count
    count=$(echo "$ASB_LAST_OUTPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d.get("discovered",[])))' 2>/dev/null)
    if [[ "$count" -lt 3 ]]; then
        echo "Expected at least 3 discovered agents, got $count" >&2
        return 1
    fi
}

test_discover_persists_custom_agent() {
    create_discovery_agent ".kodu"
    run_asb discover --auto
    assert_exit_code 0 "$ASB_LAST_STATUS"

    # Custom agent should be persisted in config
    local config_file="${XDG_CONFIG_HOME}/asb/custom_agents"
    assert_file_exists "$config_file"
    local content
    content=$(cat "$config_file")
    assert_contains "$content" "kodu"
}

test_discover_does_not_rediscover() {
    create_discovery_agent ".kodu"

    # First discovery
    run_asb discover --auto
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "Added"

    # Second discovery should find nothing new
    run_asb discover --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    assert_contains "$ASB_LAST_OUTPUT" "No new agents"
}

test_discover_ignores_known_agents() {
    # Create the agent's folder but it's already a known agent
    mkdir -p "${HOME}/.claude"
    echo '{"test": true}' > "${HOME}/.claude/settings.json"

    run_asb discover --list
    assert_exit_code 0 "$ASB_LAST_STATUS"
    # Should not list claude since it's already known
    if echo "$ASB_LAST_OUTPUT" | grep -q "\.claude.*Claude"; then
        echo "Should not discover already-known agent" >&2
        return 1
    fi
}

run_test "discover_list_finds_agents" test_discover_list_finds_agents || exit 1
run_test "discover_list_no_new_agents" test_discover_list_no_new_agents || exit 1
run_test "discover_auto_adds_agents" test_discover_auto_adds_agents || exit 1
run_test "discover_json_list" test_discover_json_list || exit 1
run_test "discover_json_auto" test_discover_json_auto || exit 1
run_test "discover_multiple_agents" test_discover_multiple_agents || exit 1
run_test "discover_persists_custom_agent" test_discover_persists_custom_agent || exit 1
run_test "discover_does_not_rediscover" test_discover_does_not_rediscover || exit 1
run_test "discover_ignores_known_agents" test_discover_ignores_known_agents || exit 1

exit 0
