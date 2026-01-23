#!/usr/bin/env bash

# Mock necessary variables and functions from asb
AGENT_NAMES=()
log_warn() { echo "WARN: $*"; }
log_error() { echo "ERROR: $*"; }
RESET=""
BOLD=""
DIM=""
RED=""
GREEN=""
YELLOW=""

# Mock git to avoid actual git operations
git() {
    if [[ "$1" == "-C" && "$3" == "archive" ]]; then
        # Mock archive extraction
        return 0
    elif [[ "$1" == "-C" && "$3" == "log" ]]; then
        echo "mock_commit_hash"
    fi
}

# Mock tar to just copy files (simplification)
tar() {
    if [[ "$1" == "-C" ]]; then
        local dest="$2"
        # In the real script, tar extracts from stdin. 
        # Here we just manually populate the temp dir to simulate extraction
        mkdir -p "$dest/folder with spaces"
        touch "$dest/folder with spaces/file with spaces.txt"
    fi
}

# Source the function to test
# We need to extract show_restore_preview from asb
# or we can just copy it here for the reproduction if sourcing is too messy
# Let's try sourcing the relevant parts or just defining it if it's self-contained

# ... actually, let's just use the real script but override the dependencies
# source ./asb # This might run main... 

# Better approach: Extract the function content to test it in isolation
# I will define the function here exactly as it is in the file (based on my read)

show_restore_preview() {
    local backup_dir="$1"
    local current_dir="$2"
    local commit="${3:-HEAD}"
    local agent_name="$4"

    RESTORE_HAS_CHANGES=false

    # Extract backup to temp for comparison
    local temp_backup
    temp_backup=$(mktemp -d)
    trap "rm -rf '$temp_backup'" RETURN

    # SIMULATE THE CONTENT directly instead of using git/tar
    mkdir -p "$temp_backup/folder with spaces"
    echo "backup content" > "$temp_backup/folder with spaces/file with spaces.txt"
    
    # Create current dir content to differ
    mkdir -p "$current_dir/folder with spaces"
    echo "current content" > "$current_dir/folder with spaces/file with spaces.txt"

    # Compare and show differences
    echo "--- Diff Output ---"
    
    local only_in_current=0
    local only_in_backup=0
    local differs=0

    # Get diff output
    local diff_output
    diff_output=$(diff -rq "$current_dir" "$temp_backup" 2>/dev/null || true)
    
    echo "$diff_output"
    echo "-------------------"

    if [[ -z "$diff_output" ]]; then
        echo "No differences"
        return 0
    fi

    RESTORE_HAS_CHANGES=true

    local entries=()

    # Parse differences into sortable entries
    while IFS= read -r line; do
        if [[ "$line" == "Only in $current_dir"* ]]; then
            # ... (omitted for brevity, focusing on 'Files ... differ')
            :
        elif [[ "$line" == "Files "* && "$line" == *" differ" ]]; then
            local file="${line#Files $current_dir/}"
            file="${file%% and *}"
            entries+=("${file}|replace")
            ((differs++))
        fi
    done <<< "$diff_output"

    echo "Parsed Entries:"
    for entry in "${entries[@]}"; do
        echo "$entry"
    done
}

# Run the test
TEST_DIR=$(mktemp -d)
echo "Running test in $TEST_DIR"
show_restore_preview "mock_backup" "$TEST_DIR" "HEAD" "TestAgent"
rm -rf "$TEST_DIR"
