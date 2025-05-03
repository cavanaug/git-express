#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- Remove Command Tests (by Path) ---

@test "remove: successfully remove a static worktree by path" {
    setup_cloned_repo # Creates test-repo and test-repo.main
    # Add another static worktree to remove
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    [ -f "../test-repo.simple-branch/simple.txt" ]

    # Remove the static worktree (setup_cloned_repo already cd'd into test-repo)
    run "$GIT_EXPRESS_PATH" remove "../test-repo.simple-branch"

    echo "$output"
    [ "$status" -eq 0 ]
    # Check directory is gone
    [ ! -d "../test-repo.simple-branch" ]
    # Check git knows it's gone (still in test-repo)
    git_output=$(git worktree list)
    [[ ! "$git_output" == *"test-repo.simple-branch"* ]]
    # Check output using the original relative path
    [[ ! "$output" == *"Interpreting"* ]] # Heuristic message should be gone
    [[ "$output" == *"Removing worktree '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]
    [[ "$output" == *"git-express remove complete for test-repo.simple-branch"* ]]
}

@test "remove: fails if worktree path does not exist and is not registered" {
    setup_cloned_repo

    run "$GIT_EXPRESS_PATH" remove "../non-existent-worktree"

    echo "$output"
    [ "$status" -ne 0 ]
    # Only expect the error message, no preceding warning for this case
    [[ "$output" == *"Error: Worktree path '../non-existent-worktree' does not exist and is not a registered worktree."* ]]
    # Ensure the warning is NOT printed
    [[ ! "$output" == *"Warning:"* ]]
}

@test "remove: fails on stale entry by path and suggests prune" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    # Manually remove the directory, leaving the git entry stale
    rm -rf "../test-repo.simple-branch"
    [ ! -d "../test-repo.simple-branch" ]

    # Check it's still listed by git (still in test-repo)
    git_output_before=$(git worktree list)
    [[ "$git_output_before" == *"test-repo.simple-branch"* ]]

    # Run remove command
    run "$GIT_EXPRESS_PATH" remove "../test-repo.simple-branch"

    echo "$output"
    [ "$status" -ne 0 ] # Expect failure
    # Check for the specific error message and prune suggestion (uses the path that was checked)
    [[ "$output" == *"Error: Worktree path '../test-repo.simple-branch' does not exist, but a registration was found."* ]]
    [[ "$output" == *"Use 'git-express prune' (not yet implemented) to remove stale worktree entries."* ]]
    # Ensure no removal messages were printed
    [[ ! "$output" == *"Removing worktree"* ]]
    [[ ! "$output" == *"Worktree removed successfully."* ]]

    # Check git *still* lists the stale entry (still in test-repo)
    git_output_after=$(git worktree list)
    [[ "$git_output_after" == *"test-repo.simple-branch"* ]]
}


@test "remove: fails if path exists but is not a registered worktree" {
    setup_cloned_repo
    # Create a directory that looks like a worktree but isn't registered
    mkdir "../test-repo.fake-worktree"
    touch "../test-repo.fake-worktree/somefile.txt"

    run "$GIT_EXPRESS_PATH" remove "../test-repo.fake-worktree"

    echo "$output"
    [ "$status" -ne 0 ]
    # Check the combined error message
    [[ "$output" == *"Error: Could not find a registered worktree matching '../test-repo.fake-worktree' (checked as path and branch name)."* ]]
    [[ "$output" == *"Path '../test-repo.fake-worktree' exists but is not a registered worktree."* ]]
    # Cleanup the fake directory
    rm -rf "../test-repo.fake-worktree"
}


@test "remove: fails if attempting to remove the main (dynamic) worktree" {
    setup_cloned_repo # Creates test-repo (dynamic) and test-repo.main (static)

    # Try to remove the dynamic worktree ('test-repo') from within itself (already cd'd into it)
    run "$GIT_EXPRESS_PATH" remove "." # '.' refers to the dynamic worktree here

    echo "$output"
    [ "$status" -ne 0 ]
    # The path reported might be absolute after realpath resolution
    [[ "$output" == *"Error: Cannot remove the main (dynamic) worktree"* ]]
}

@test "remove: fails if worktree has uncommitted changes (without --force)" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    # Make uncommitted changes
    echo "uncommitted change" >> "../test-repo.simple-branch/simple.txt"

    run "$GIT_EXPRESS_PATH" remove "../test-repo.simple-branch"

    echo "$output"
    [ "$status" -ne 0 ]
    # Check output using the original relative path
    [[ ! "$output" == *"Interpreting"* ]]
    [[ "$output" == *"Removing worktree '../test-repo.simple-branch'"* ]] # Should still attempt
    [[ "$output" == *"Error: Failed to remove worktree '../test-repo.simple-branch'."* ]]
    # Verify directory still exists
    [ -d "../test-repo.simple-branch" ]
}

@test "remove: succeeds with uncommitted changes using --force" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    # Make uncommitted changes
    echo "uncommitted change" >> "../test-repo.simple-branch/simple.txt"

    run "$GIT_EXPRESS_PATH" remove --force "../test-repo.simple-branch"

    echo "$output"
    [ "$status" -eq 0 ]
    # Check output using the original relative path
    [[ ! "$output" == *"Interpreting"* ]]
    [[ "$output" == *"Force removing worktree '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]
    # Verify directory is gone
    [ ! -d "../test-repo.simple-branch" ]
}

@test "remove: succeeds with uncommitted changes using -f" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    # Make uncommitted changes
    echo "uncommitted change" >> "../test-repo.simple-branch/simple.txt"

    run "$GIT_EXPRESS_PATH" remove -f "../test-repo.simple-branch"

    echo "$output"
    [ "$status" -eq 0 ]
    # Check output using the original relative path
    [[ ! "$output" == *"Interpreting"* ]]
    [[ "$output" == *"Force removing worktree '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]
    # Verify directory is gone
    [ ! -d "../test-repo.simple-branch" ]
}


@test "remove: fails if not inside a git repository" {
    # Run from the main test temp dir, not inside a repo clone
    run "$GIT_EXPRESS_PATH" remove some/path
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Not inside a git repository or worktree."* ]]
}

@test "remove: quiet mode suppresses informational messages" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]

    # Use --quiet for the remove command (already in test-repo)
    run "$GIT_EXPRESS_PATH" remove -q "../test-repo.simple-branch"

    echo "Output: $output" # Should be empty or only contain git errors if any
    [ "$status" -eq 0 ]
    [ ! -d "../test-repo.simple-branch" ]
    # Check that git-express informational output is suppressed
    [[ ! "$output" == *"Interpreting"* ]]
    [[ ! "$output" == *"Removing worktree"* ]]
    [[ ! "$output" == *"Worktree removed successfully."* ]]
    [[ ! "$output" == *"git-express remove complete"* ]]
    # git worktree remove itself doesn't have quiet mode, so no need to check its output suppression
}

# --- Remove Command Tests (by Branch Name) ---

@test "remove: successfully remove a static worktree by branch name" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]

    # Remove using the branch name
    run "$GIT_EXPRESS_PATH" remove simple-branch

    echo "$output"
    [ "$status" -eq 0 ]
    # Check directory is gone
    [ ! -d "../test-repo.simple-branch" ]
    # Check git knows it's gone
    git_output=$(git worktree list)
    [[ ! "$git_output" == *"test-repo.simple-branch"* ]]
    # Check output - should show the derived path in the removal message
    [[ "$output" == *"Input 'simple-branch' did not match a registered worktree path. Trying as branch name..."* ]]
    [[ "$output" == *"Removing worktree '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]
    [[ "$output" == *"git-express remove complete for test-repo.simple-branch"* ]]
}

@test "remove: successfully remove worktree by branch name with slash" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q feature/test-branch
    [ -d "../test-repo.feature-test-branch" ]

    # Remove using the branch name with slash
    run "$GIT_EXPRESS_PATH" remove feature/test-branch

    echo "$output"
    [ "$status" -eq 0 ]
    [ ! -d "../test-repo.feature-test-branch" ]
    git_output=$(git worktree list)
    [[ ! "$git_output" == *"test-repo.feature-test-branch"* ]]
    # Check output - should show the derived path in the removal message
    [[ "$output" == *"Input 'feature/test-branch' did not match a registered worktree path. Trying as branch name..."* ]]
    [[ "$output" == *"Removing worktree '../test-repo.feature-test-branch'"* ]]
    [[ "$output" == *"git-express remove complete for test-repo.feature-test-branch"* ]]
}


@test "remove: fails if branch name does not exist" {
    setup_cloned_repo
    run "$GIT_EXPRESS_PATH" remove non-existent-branch
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Input 'non-existent-branch' did not match a registered worktree path. Trying as branch name..."* ]]
    # Check the combined error message
    [[ "$output" == *"Error: Could not find a registered worktree matching 'non-existent-branch' (checked as path and branch name)."* ]]
    [[ "$output" == *"Path 'non-existent-branch' does not exist."* ]]
    [[ "$output" == *"Branch 'non-existent-branch' does not exist."* ]]
}

@test "remove: fails if branch exists but has no corresponding static worktree" {
    setup_cloned_repo
    # 'main' branch exists, but its static worktree is test-repo.main
    # Let's try removing 'main' by name - it should fail as it doesn't map to a removable static worktree
    # (The dynamic worktree isn't removable by this command, and 'main' doesn't map to a removable static worktree)
    run "$GIT_EXPRESS_PATH" remove main
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Input 'main' did not match a registered worktree path. Trying as branch name..."* ]]
    # It should find the derived path ../test-repo.main, find it's registered, but fail because it's not the main worktree path.
    # The error should indicate no *removable* static worktree was found.
    [[ "$output" == *"Error: Could not find a registered worktree matching 'main' (checked as path and branch name)."* ]]
    [[ "$output" == *"Branch 'main' exists, but no corresponding static worktree was found."* ]]

    # --- Test removing a branch that exists but whose worktree was manually deleted (stale by branch name) ---
    # setup_cloned_repo is already done above
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    rm -rf "../test-repo.simple-branch" # Manually delete dir
    [ ! -d "../test-repo.simple-branch" ]
    git show-ref --verify --quiet "refs/heads/simple-branch" # Branch still exists

    run "$GIT_EXPRESS_PATH" remove simple-branch
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Input 'simple-branch' did not match a registered worktree path. Trying as branch name..."* ]]
    [[ "$output" == *"Error: Worktree path '../test-repo.simple-branch' does not exist, but a registration was found."* ]]
    [[ "$output" == *"Use 'git-express prune' (not yet implemented) to remove stale worktree entries."* ]]
}

@test "remove: quiet mode by branch name suppresses informational messages" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]

    # Use --quiet for the remove command by branch name
    run "$GIT_EXPRESS_PATH" remove -q simple-branch

    echo "Output: $output" # Should be empty or only contain git errors if any
    [ "$status" -eq 0 ]
    [ ! -d "../test-repo.simple-branch" ]
    # Check that git-express informational output is suppressed
    [[ ! "$output" == *"Interpreting"* ]]
    [[ ! "$output" == *"Removing worktree"* ]]
    [[ ! "$output" == *"Worktree removed successfully."* ]]
    [[ ! "$output" == *"git-express remove complete"* ]]
}
