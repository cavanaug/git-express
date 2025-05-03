#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- List Command Tests ---

@test "list: basic listing after clone from dynamic worktree" {
    # Setup: Clone the repo. setup_cloned_repo cds into the dynamic worktree.
    setup_cloned_repo "list-repo"

    # Action: Run the list command
    run "$GIT_EXPRESS_PATH" list
    echo "Output:"
    echo "$output"

    # Assertions
    [ "$status" -eq 0 ]

    # Define expected paths
    local main_wt_path="$TEST_TEMP_DIR/list-repo"
    local static_wt_path="$TEST_TEMP_DIR/list-repo.main"

    # Check for the dynamic worktree line (should be current)
    # Use simple contains check first
    [[ "$output" == *" main (dynamic)"* ]] || fail "Missing 'main (dynamic)' marker"
    [[ "$output" == *"$main_wt_path"* ]] || fail "Missing dynamic worktree path '$main_wt_path'"
    # Check for the asterisk indicating current worktree
    # Note: Need to be careful with globbing if not using regex
    run bash -c "echo \$'${output}' | grep -q '^* main (dynamic)'"
    [ "$status" -eq 0 ] || fail "Dynamic worktree line not marked as current ('*')"


    # Check for the static worktree line (should not be current)
    # Use simple contains check first
    [[ "$output" == *" main"* ]] || fail "Missing static 'main' branch line"
    [[ "$output" != *" main (dynamic)"* ]] || fail "Static 'main' line incorrectly marked as dynamic"
    [[ "$output" == *"$static_wt_path"* ]] || fail "Missing static worktree path '$static_wt_path'"
     # Check it's NOT marked as current
    run bash -c "echo \$'${output}' | grep -q '^  main '"
    [ "$status" -eq 0 ] || fail "Static worktree line incorrectly marked as current or missing prefix spaces"

}

# Add more tests here later, e.g., running from static worktree, multiple worktrees, etc.
