#!/usr/bin/env bash
#
# Unit Tests: Discovery Functions
# Tests scan_for_agents, load_custom_agents, save_custom_agent
#

# ============================================
# scan_for_agents tests
# ============================================

test_scan_finds_discoverable_agent() {
    # Create a discoverable agent folder (.kodu is in DISCOVERY_PATTERNS)
    mkdir -p "${HOME}/.kodu"
    echo '{"test": true}' > "${HOME}/.kodu/settings.json"

    local result
    result=$(scan_for_agents 2>/dev/null)

    assert_contains "$result" "kodu" || { echo "Should find .kodu agent" >&2; return 1; }
}

test_scan_returns_name_pair() {
    mkdir -p "${HOME}/.kodu"

    local result
    result=$(scan_for_agents 2>/dev/null)

    # Should contain both folder and name
    assert_contains "$result" "Kodu" || { echo "Should include human-readable name" >&2; return 1; }
}

test_scan_ignores_known_agents() {
    # Create .claude folder (but claude is already a known agent)
    mkdir -p "${HOME}/.claude"

    local result
    result=$(scan_for_agents 2>/dev/null)

    # Should NOT discover .claude since it's already in AGENT_FOLDERS
    if [[ "$result" == *"claude"* ]] && [[ "$result" != *".kodu"* ]]; then
        # If only result is claude-related, that's wrong
        if echo "$result" | grep -q "^\.claude"; then
            echo "Should not discover already-known agents like claude" >&2
            return 1
        fi
    fi
}

test_scan_empty_home() {
    # Don't create any discoverable folders
    local result
    result=$(scan_for_agents 2>/dev/null)

    # Should return empty or "none found" message
    # Either empty result or specific message is acceptable
}

test_scan_ignores_regular_files() {
    # Create a file (not directory) matching pattern
    touch "${HOME}/.kodu"  # file, not directory

    local result
    result=$(scan_for_agents 2>/dev/null)

    # Should NOT include .kodu since it's a file
    if [[ "$result" == *".kodu"* ]]; then
        echo "Should ignore files, only discover directories" >&2
        rm -f "${HOME}/.kodu"
        return 1
    fi
    rm -f "${HOME}/.kodu"
}

test_scan_multiple_agents() {
    mkdir -p "${HOME}/.kodu"
    mkdir -p "${HOME}/.continue"
    mkdir -p "${HOME}/.tabby"

    local result
    result=$(scan_for_agents 2>/dev/null)

    # Should find all three
    local count
    count=$(echo "$result" | grep -c '.' || echo 0)

    if [[ "$count" -lt 3 ]]; then
        echo "Should find multiple discoverable agents" >&2
        return 1
    fi
}

# ============================================
# load_custom_agents tests
# ============================================

test_load_custom_agents_empty() {
    # No custom_agents file
    rm -f "${XDG_CONFIG_HOME}/asb/custom_agents"

    # Should not fail
    load_custom_agents || return 1
}

test_load_custom_agents_adds_to_array() {
    local custom_file="${XDG_CONFIG_HOME}/asb/custom_agents"
    mkdir -p "${XDG_CONFIG_HOME}/asb"

    # Create custom agents file
    cat > "$custom_file" << 'EOF'
kodu=.kodu
myagent=.myagent
EOF

    load_custom_agents

    # Check if custom agent was added
    if ! agent_exists "kodu" 2>/dev/null; then
        echo "Custom agent 'kodu' should exist after loading" >&2
        return 1
    fi
}

# ============================================
# save_custom_agent tests
# ============================================

test_save_custom_agent_creates_file() {
    local custom_file="${XDG_CONFIG_HOME}/asb/custom_agents"
    rm -f "$custom_file"
    mkdir -p "${XDG_CONFIG_HOME}/asb"

    save_custom_agent "testagent" ".testagent" "Test Agent" >/dev/null 2>&1

    assert_file_exists "$custom_file" || return 1
}

test_save_custom_agent_content() {
    local custom_file="${XDG_CONFIG_HOME}/asb/custom_agents"
    rm -f "$custom_file"
    mkdir -p "${XDG_CONFIG_HOME}/asb"

    save_custom_agent "newagent" ".newagent" "New Agent" >/dev/null 2>&1

    local content
    content=$(cat "$custom_file")

    assert_contains "$content" "newagent" || return 1
    assert_contains "$content" ".newagent" || return 1
}

test_save_custom_agent_append() {
    local custom_file="${XDG_CONFIG_HOME}/asb/custom_agents"
    mkdir -p "${XDG_CONFIG_HOME}/asb"
    echo "existing=.existing" > "$custom_file"

    save_custom_agent "newagent" ".newagent" "New Agent" >/dev/null 2>&1

    local content
    content=$(cat "$custom_file")

    # Should have both
    assert_contains "$content" "existing" || { echo "Should preserve existing entries" >&2; return 1; }
    assert_contains "$content" "newagent" || { echo "Should add new entry" >&2; return 1; }
}

# Run all tests
run_unit_test "scan_finds_discoverable_agent" test_scan_finds_discoverable_agent
run_unit_test "scan_returns_name_pair" test_scan_returns_name_pair
run_unit_test "scan_ignores_known_agents" test_scan_ignores_known_agents
run_unit_test "scan_empty_home" test_scan_empty_home
run_unit_test "scan_ignores_regular_files" test_scan_ignores_regular_files
run_unit_test "scan_multiple_agents" test_scan_multiple_agents
run_unit_test "load_custom_agents_empty" test_load_custom_agents_empty
run_unit_test "load_custom_agents_adds_to_array" test_load_custom_agents_adds_to_array
run_unit_test "save_custom_agent_creates_file" test_save_custom_agent_creates_file
run_unit_test "save_custom_agent_content" test_save_custom_agent_content
run_unit_test "save_custom_agent_append" test_save_custom_agent_append
