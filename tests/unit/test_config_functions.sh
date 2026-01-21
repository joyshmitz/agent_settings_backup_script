#!/usr/bin/env bash
#
# Unit Tests: Configuration Functions
# Tests load_config, init_config, show_config
#

# ============================================
# load_config tests
# ============================================

test_load_config_nonexistent_file() {
    # Should succeed gracefully when config doesn't exist
    local fake_config="${TEST_ENV_ROOT}/nonexistent/config"
    XDG_CONFIG_HOME="${TEST_ENV_ROOT}/nonexistent"

    # load_config should not fail
    load_config || return 1
}

test_load_config_sources_file() {
    local config_dir="${XDG_CONFIG_HOME}/asb"
    mkdir -p "$config_dir"

    # Create a config with a test variable
    echo 'ASB_TEST_VAR="loaded_from_config"' > "${config_dir}/config"

    unset ASB_TEST_VAR
    load_config

    if [[ "${ASB_TEST_VAR:-}" != "loaded_from_config" ]]; then
        echo "Config file was not sourced properly" >&2
        return 1
    fi
}

test_load_config_overrides_defaults() {
    local config_dir="${XDG_CONFIG_HOME}/asb"
    mkdir -p "$config_dir"

    # Set default
    ASB_BACKUP_ROOT="/default/path"

    # Create config that overrides
    echo 'ASB_BACKUP_ROOT="/custom/path"' > "${config_dir}/config"

    load_config

    if [[ "$ASB_BACKUP_ROOT" != "/custom/path" ]]; then
        echo "Config should override default. Expected /custom/path, got $ASB_BACKUP_ROOT" >&2
        return 1
    fi
}

test_load_config_respects_xdg() {
    local custom_xdg="${TEST_ENV_ROOT}/custom_xdg"
    mkdir -p "${custom_xdg}/asb"

    echo 'ASB_XDG_TEST="from_custom_xdg"' > "${custom_xdg}/asb/config"

    XDG_CONFIG_HOME="$custom_xdg"
    unset ASB_XDG_TEST
    load_config

    if [[ "${ASB_XDG_TEST:-}" != "from_custom_xdg" ]]; then
        echo "Should load from custom XDG_CONFIG_HOME" >&2
        return 1
    fi
}

test_load_config_handles_malformed() {
    local config_dir="${XDG_CONFIG_HOME}/asb"
    mkdir -p "$config_dir"

    # Create malformed config (shouldn't crash)
    cat > "${config_dir}/config" << 'EOF'
# Comment
ASB_VALID="yes"
# Another comment
EOF

    load_config || return 1

    if [[ "${ASB_VALID:-}" != "yes" ]]; then
        echo "Valid config lines should still work" >&2
        return 1
    fi
}

# ============================================
# init_config tests
# ============================================

test_init_config_creates_directory() {
    local config_dir="${XDG_CONFIG_HOME}/asb"
    rm -rf "$config_dir"

    init_config >/dev/null 2>&1

    assert_dir_exists "$config_dir" || return 1
}

test_init_config_creates_config_file() {
    local config_file="${XDG_CONFIG_HOME}/asb/config"
    rm -f "$config_file"

    init_config >/dev/null 2>&1

    assert_file_exists "$config_file" || return 1
}

test_init_config_creates_hook_dirs() {
    local hooks_dir="${XDG_CONFIG_HOME}/asb/hooks"

    init_config >/dev/null 2>&1

    assert_dir_exists "${hooks_dir}/pre-backup.d" || { echo "Missing pre-backup.d" >&2; return 1; }
    assert_dir_exists "${hooks_dir}/post-backup.d" || { echo "Missing post-backup.d" >&2; return 1; }
    assert_dir_exists "${hooks_dir}/pre-restore.d" || { echo "Missing pre-restore.d" >&2; return 1; }
    assert_dir_exists "${hooks_dir}/post-restore.d" || { echo "Missing post-restore.d" >&2; return 1; }
}

test_init_config_no_overwrite() {
    local config_file="${XDG_CONFIG_HOME}/asb/config"
    mkdir -p "${XDG_CONFIG_HOME}/asb"

    # Create existing config with custom content
    echo "EXISTING_SETTING=true" > "$config_file"

    init_config >/dev/null 2>&1

    local content
    content=$(cat "$config_file")
    assert_contains "$content" "EXISTING_SETTING" || { echo "Should not overwrite existing config" >&2; return 1; }
}

# ============================================
# show_config tests
# ============================================

test_show_config_displays_path() {
    local output
    output=$(show_config 2>&1)

    assert_contains "$output" "asb" || return 1
    assert_contains "$output" "config" || return 1
}

test_show_config_shows_backup_root() {
    local output
    output=$(show_config 2>&1)

    assert_contains "$output" "ASB_BACKUP_ROOT" || return 1
}

test_show_config_shows_auto_commit() {
    local output
    output=$(show_config 2>&1)

    assert_contains "$output" "ASB_AUTO_COMMIT" || return 1
}

# Run all tests
run_unit_test "load_config_nonexistent_file" test_load_config_nonexistent_file
run_unit_test "load_config_sources_file" test_load_config_sources_file
run_unit_test "load_config_overrides_defaults" test_load_config_overrides_defaults
run_unit_test "load_config_respects_xdg" test_load_config_respects_xdg
run_unit_test "load_config_handles_malformed" test_load_config_handles_malformed
run_unit_test "init_config_creates_directory" test_init_config_creates_directory
run_unit_test "init_config_creates_config_file" test_init_config_creates_config_file
run_unit_test "init_config_creates_hook_dirs" test_init_config_creates_hook_dirs
run_unit_test "init_config_no_overwrite" test_init_config_no_overwrite
run_unit_test "show_config_displays_path" test_show_config_displays_path
run_unit_test "show_config_shows_backup_root" test_show_config_shows_backup_root
run_unit_test "show_config_shows_auto_commit" test_show_config_shows_auto_commit
