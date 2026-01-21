#!/usr/bin/env bash
#
# Test Logging Framework
# Provides structured logging for test execution
#

# Log levels
LOG_DEBUG=0
LOG_INFO=1
LOG_WARN=2
LOG_ERROR=3

# Configuration
LOG_LEVEL=${LOG_LEVEL:-$LOG_INFO}
LOG_FILE=${LOG_FILE:-}
LOG_COLOR=${LOG_COLOR:-auto}

# Color codes (set based on LOG_COLOR setting)
_setup_colors() {
    if [[ "$LOG_COLOR" == "always" ]] || { [[ "$LOG_COLOR" == "auto" ]] && [[ -t 2 ]]; }; then
        LOG_RED='\033[0;31m'
        LOG_GREEN='\033[0;32m'
        LOG_YELLOW='\033[0;33m'
        LOG_BLUE='\033[0;34m'
        LOG_CYAN='\033[0;36m'
        LOG_BOLD='\033[1m'
        LOG_DIM='\033[2m'
        LOG_RESET='\033[0m'
    else
        LOG_RED='' LOG_GREEN='' LOG_YELLOW='' LOG_BLUE='' LOG_CYAN='' LOG_BOLD='' LOG_DIM='' LOG_RESET=''
    fi
}
_setup_colors

# Current test name (set by run_test)
_CURRENT_TEST=""

# Get timestamp with milliseconds
_log_timestamp() {
    date '+%Y-%m-%d %H:%M:%S.%3N'
}

# Internal log function
_log() {
    local level="$1"
    local level_name="$2"
    local color="$3"
    shift 3
    local message="$*"

    [[ $level -lt $LOG_LEVEL ]] && return 0

    local timestamp
    timestamp=$(_log_timestamp)
    local test_part=""
    [[ -n "$_CURRENT_TEST" ]] && test_part=" [${_CURRENT_TEST}]"

    local formatted="[${timestamp}] [${level_name}]${test_part} ${message}"

    # Output to stderr with color
    printf '%b%s%b\n' "$color" "$formatted" "$LOG_RESET" >&2

    # Output to log file without color
    if [[ -n "$LOG_FILE" ]]; then
        echo "$formatted" >> "$LOG_FILE"
    fi
}

# Public logging functions
log_debug() {
    _log $LOG_DEBUG "DEBUG" "$LOG_DIM" "$@"
}

log_info() {
    _log $LOG_INFO "INFO " "$LOG_BLUE" "$@"
}

log_warn() {
    _log $LOG_WARN "WARN " "$LOG_YELLOW" "$@"
}

log_error() {
    _log $LOG_ERROR "ERROR" "$LOG_RED" "$@"
    # Include stack trace for errors
    if [[ ${BASH_LINENO[0]} -gt 0 ]]; then
        local i=0
        while [[ ${BASH_LINENO[$i]+_} ]]; do
            local func="${FUNCNAME[$((i+1))]:-main}"
            local line="${BASH_LINENO[$i]}"
            local src="${BASH_SOURCE[$((i+1))]:-unknown}"
            _log $LOG_ERROR "     " "$LOG_DIM" "  at ${func}() in ${src}:${line}"
            ((i++))
        done
    fi
}

# Section header for visual grouping
log_section() {
    local title="$1"
    local line="════════════════════════════════════════════════════════════"
    printf '\n%b%s%b\n' "$LOG_BOLD" "$line" "$LOG_RESET" >&2
    printf '%b  %s%b\n' "$LOG_BOLD" "$title" "$LOG_RESET" >&2
    printf '%b%s%b\n\n' "$LOG_BOLD" "$line" "$LOG_RESET" >&2
}

# Test result logging
log_pass() {
    printf '%b✓ PASS:%b %s\n' "$LOG_GREEN" "$LOG_RESET" "$*" >&2
}

log_fail() {
    printf '%b✗ FAIL:%b %s\n' "$LOG_RED" "$LOG_RESET" "$*" >&2
}

log_skip() {
    printf '%b⊘ SKIP:%b %s\n' "$LOG_YELLOW" "$LOG_RESET" "$*" >&2
}

# Set current test name
set_current_test() {
    _CURRENT_TEST="$1"
}

# Clear current test name
clear_current_test() {
    _CURRENT_TEST=""
}
