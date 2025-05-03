#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- Remove Command Tests ---

@test "remove: successfully remove a static worktree" {
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
    [[ "$output" == *"Removing worktree '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]
    [[ "$output" == *"git-express remove complete for test-repo.simple-branch"* ]]
}

@test "remove: fails if worktree path does not exist and is not registered" {
    setup_cloned_repo

    run "$GIT_EXPRESS_PATH" remove "../non-existent-worktree"

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Warning: Worktree path '../non-existent-worktree' does not exist."* ]]
    [[ "$output" == *"Error: Worktree path '../non-existent-worktree' does not exist and is not a registered worktree."* ]]
}

@test "remove: successfully removes a stale worktree entry (path deleted manually)" {
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
    [ "$status" -eq 0 ]
    # Check for the corrected warning and removal messages
    [[ "$output" == *"Warning: Worktree path '../test-repo.simple-branch' does not exist. Found stale registration."* ]]
    [[ "$output" == *"Removing worktree '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]

    # Check git knows it's gone (still in test-repo)
    git_output_after=$(git worktree list)
    [[ ! "$git_output_after" == *"test-repo.simple-branch"* ]]
}


@test "remove: fails if path exists but is not a registered worktree" {
    setup_cloned_repo
    # Create a directory that looks like a worktree but isn't registered
    mkdir "../test-repo.fake-worktree"
    touch "../test-repo.fake-worktree/somefile.txt"

    run "$GIT_EXPRESS_PATH" remove "../test-repo.fake-worktree"

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: '../test-repo.fake-worktree' exists but is not a registered git worktree for this repository."* ]]
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
    [[ ! "$output" == *"Removing worktree"* ]]
    [[ ! "$output" == *"Worktree removed successfully."* ]]
    [[ ! "$output" == *"git-express remove complete"* ]]
    # git worktree remove itself doesn't have quiet mode, so no need to check its output suppression
}
