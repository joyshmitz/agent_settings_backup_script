#!/usr/bin/env bash
#
# Unit Tests: JSON Functions
# Tests json_escape_string, json_output, json_error, json_array
#

# ============================================
# json_escape_string tests
# ============================================

test_json_escape_backslash() {
    local input='path\to\file'
    local expected='path\\to\\file'
    local result
    result=$(json_escape_string "$input")

    assert_equals "$expected" "$result" || return 1
}

test_json_escape_double_quotes() {
    local input='say "hello"'
    local expected='say \"hello\"'
    local result
    result=$(json_escape_string "$input")

    assert_equals "$expected" "$result" || return 1
}

test_json_escape_newlines() {
    local input=$'line1\nline2'
    local expected='line1\nline2'
    local result
    result=$(json_escape_string "$input")

    assert_equals "$expected" "$result" || return 1
}

test_json_escape_carriage_returns() {
    local input=$'line1\rline2'
    local expected='line1\rline2'
    local result
    result=$(json_escape_string "$input")

    assert_equals "$expected" "$result" || return 1
}

test_json_escape_tabs() {
    local input=$'col1\tcol2'
    local expected='col1\tcol2'
    local result
    result=$(json_escape_string "$input")

    assert_equals "$expected" "$result" || return 1
}

test_json_escape_empty_string() {
    local result
    result=$(json_escape_string "")

    assert_equals "" "$result" || return 1
}

test_json_escape_unicode_preserved() {
    local input='日本語テスト'
    local result
    result=$(json_escape_string "$input")

    # Unicode should pass through unchanged
    assert_equals "$input" "$result" || return 1
}

test_json_escape_mixed_special_chars() {
    local input=$'path\\to\n"file"\twith\rspecial'
    local result
    result=$(json_escape_string "$input")

    # All special chars should be escaped
    assert_contains "$result" '\n' || { echo "Missing escaped newline" >&2; return 1; }
    assert_contains "$result" '\t' || { echo "Missing escaped tab" >&2; return 1; }
    assert_contains "$result" '\r' || { echo "Missing escaped carriage return" >&2; return 1; }
    assert_contains "$result" '\"' || { echo "Missing escaped quote" >&2; return 1; }
}

test_json_escape_normal_text_unchanged() {
    local input='normal text 123 ABC'
    local result
    result=$(json_escape_string "$input")

    assert_equals "$input" "$result" || return 1
}

# ============================================
# json_output tests
# ============================================

test_json_output_prints_string() {
    local result
    result=$(json_output '{"test": true}')

    assert_equals '{"test": true}' "$result" || return 1
}

# ============================================
# is_json_output tests
# ============================================

test_is_json_output_false_by_default() {
    JSON_OUTPUT=false
    if is_json_output; then
        echo "is_json_output should return false when JSON_OUTPUT=false" >&2
        return 1
    fi
}

test_is_json_output_true_when_set() {
    JSON_OUTPUT=true
    if ! is_json_output; then
        echo "is_json_output should return true when JSON_OUTPUT=true" >&2
        JSON_OUTPUT=false
        return 1
    fi
    JSON_OUTPUT=false
}

# ============================================
# json_array tests (if function exists)
# ============================================

test_json_array_empty() {
    if ! declare -F json_array >/dev/null 2>&1; then
        return 2  # Skip if function doesn't exist
    fi

    local result
    result=$(json_array)

    assert_equals "[]" "$result" || return 1
}

test_json_array_single_item() {
    if ! declare -F json_array >/dev/null 2>&1; then
        return 2  # Skip if function doesn't exist
    fi

    local result
    result=$(json_array '"item1"')

    assert_equals '["item1"]' "$result" || return 1
}

test_json_array_multiple_items() {
    if ! declare -F json_array >/dev/null 2>&1; then
        return 2  # Skip if function doesn't exist
    fi

    local result
    result=$(json_array '"a"' '"b"' '"c"')

    assert_equals '["a","b","c"]' "$result" || return 1
}

# Run all tests
run_unit_test "json_escape_backslash" test_json_escape_backslash
run_unit_test "json_escape_double_quotes" test_json_escape_double_quotes
run_unit_test "json_escape_newlines" test_json_escape_newlines
run_unit_test "json_escape_carriage_returns" test_json_escape_carriage_returns
run_unit_test "json_escape_tabs" test_json_escape_tabs
run_unit_test "json_escape_empty_string" test_json_escape_empty_string
run_unit_test "json_escape_unicode_preserved" test_json_escape_unicode_preserved
run_unit_test "json_escape_mixed_special_chars" test_json_escape_mixed_special_chars
run_unit_test "json_escape_normal_text_unchanged" test_json_escape_normal_text_unchanged
run_unit_test "json_output_prints_string" test_json_output_prints_string
run_unit_test "is_json_output_false_by_default" test_is_json_output_false_by_default
run_unit_test "is_json_output_true_when_set" test_is_json_output_true_when_set
run_unit_test "json_array_empty" test_json_array_empty
run_unit_test "json_array_single_item" test_json_array_single_item
run_unit_test "json_array_multiple_items" test_json_array_multiple_items
