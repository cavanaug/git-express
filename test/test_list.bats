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
    [[ "$output" == *" main (dynamic)"* ]]
    [[ "$output" == *"$main_wt_path"* ]]
    # Check for the asterisk indicating current worktree
    # Note: Need to be careful with globbing if not using regex
    run bash -c "echo \$'${output}' | grep -q '^* main (dynamic)'"
    [ "$status" -eq 0 ]


    # Check for the static worktree line (should not be current)
    # Use simple contains check first
    [[ "$output" == *" main"* ]]
    [[ "$output" != *" main (dynamic)"* ]] # Check it's not marked dynamic
    [[ "$output" == *"$static_wt_path"* ]]
     # Check it's NOT marked as current (starts with two spaces)
    run bash -c "echo \$'${output}' | grep -q '^  main '"
    [ "$status" -eq 0 ]

}

# Add more tests here later, e.g., running from static worktree, multiple worktrees, etc.
