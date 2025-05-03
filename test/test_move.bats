#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- Move Command Tests ---

@test "move: successfully move a static worktree to a new location" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    [ -f "../test-repo.simple-branch/simple.txt" ]

    # Create a target directory to move to
    mkdir -p "../new-location"
    
    # Move the worktree
    run "$GIT_EXPRESS_PATH" move "../test-repo.simple-branch" "../new-location/test-repo.simple-branch"

    echo "$output"
    [ "$status" -eq 0 ]
    # Check old directory is gone
    [ ! -d "../test-repo.simple-branch" ]
    # Check new directory exists with content
    [ -d "../new-location/test-repo.simple-branch" ]
    [ -f "../new-location/test-repo.simple-branch/simple.txt" ]
    # Check git knows about the new location
    git_output=$(git worktree list)
    [[ "$git_output" == *"new-location/test-repo.simple-branch"* ]]
    # Check output
    [[ "$output" == *"Moving worktree from '../test-repo.simple-branch' to '../new-location/test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree moved successfully."* ]]
    [[ "$output" == *"git-express move complete"* ]]
}

@test "move: fails if source worktree does not exist" {
    setup_cloned_repo
    
    run "$GIT_EXPRESS_PATH" move "../non-existent-worktree" "../new-location"

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Source worktree '../non-existent-worktree' does not exist."* ]]
}

@test "move: fails if source is not a registered worktree" {
    setup_cloned_repo
    # Create a directory that looks like a worktree but isn't registered
    mkdir "../test-repo.fake-worktree"
    touch "../test-repo.fake-worktree/somefile.txt"

    run "$GIT_EXPRESS_PATH" move "../test-repo.fake-worktree" "../new-location"

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Source path '../test-repo.fake-worktree' is not a registered git worktree."* ]]
    
    # Cleanup the fake directory
    rm -rf "../test-repo.fake-worktree"
}

@test "move: fails if attempting to move the main (dynamic) worktree" {
    setup_cloned_repo # Creates test-repo (dynamic) and test-repo.main (static)

    # Try to move the dynamic worktree
    run "$GIT_EXPRESS_PATH" move "." "../new-location"

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Cannot move the main (dynamic) worktree"* ]]
    [[ "$output" == *"git-express only supports moving static worktrees."* ]]
}

@test "move: fails if target parent directory does not exist" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    
    # Try to move to a non-existent parent directory
    run "$GIT_EXPRESS_PATH" move "../test-repo.simple-branch" "../non-existent-dir/test-repo.simple-branch"

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Parent directory of target path '../non-existent-dir' does not exist."* ]]
    # Original worktree should still exist
    [ -d "../test-repo.simple-branch" ]
}

@test "move: quiet mode suppresses informational messages" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    mkdir -p "../new-location"
    
    # Use --quiet for the move command
    run "$GIT_EXPRESS_PATH" move -q "../test-repo.simple-branch" "../new-location/test-repo.simple-branch"

    echo "Output: $output" # Should be empty or only contain git errors if any
    [ "$status" -eq 0 ]
    # Check old directory is gone and new one exists
    [ ! -d "../test-repo.simple-branch" ]
    [ -d "../new-location/test-repo.simple-branch" ]
    # Check that git-express informational output is suppressed
    [[ ! "$output" == *"Moving worktree"* ]]
    [[ ! "$output" == *"Worktree moved successfully."* ]]
    [[ ! "$output" == *"git-express move complete"* ]]
}

@test "move: works when run from outside a git repository" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    mkdir -p "../new-location"
    
    # Get absolute paths before moving outside the repo
    local abs_source_path="$TEST_TEMP_DIR/test-repo.simple-branch"
    local abs_target_path="$TEST_TEMP_DIR/new-location/test-repo.simple-branch"
    
    # Move to a directory outside the git repository
    cd "$TEST_TEMP_DIR"
    
    # Run the move command from outside the git repository with absolute paths
    run "$GIT_EXPRESS_PATH" move "$abs_source_path" "$abs_target_path"

    echo "$output"
    [ "$status" -eq 0 ]
    # Check old directory is gone
    [ ! -d "test-repo.simple-branch" ]
    # Check new directory exists with content
    [ -d "new-location/test-repo.simple-branch" ]
    [ -f "new-location/test-repo.simple-branch/simple.txt" ]
    # Check output - using basename to match the actual output which uses absolute paths
    [[ "$output" == *"Moving worktree from"* ]]
    [[ "$output" == *"Worktree moved successfully."* ]]
    [[ "$output" == *"git-express move complete"* ]]
}
