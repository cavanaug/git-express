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

    # Remove the static worktree
    # Need to run from within a worktree (e.g., the dynamic one)
    pushd "test-repo" >/dev/null
    run "$GIT_EXPRESS_PATH" remove "../test-repo.simple-branch"
    popd >/dev/null

    echo "$output"
    [ "$status" -eq 0 ]
    # Check directory is gone
    [ ! -d "../test-repo.simple-branch" ]
    # Check git knows it's gone
    pushd "test-repo" >/dev/null
    git_output=$(git worktree list)
    popd >/dev/null
    [[ ! "$git_output" == *"test-repo.simple-branch"* ]]
    [[ "$output" == *"Removing worktree '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]
    [[ "$output" == *"git-express remove complete for test-repo.simple-branch"* ]]
}

@test "remove: fails if worktree path does not exist and is not registered" {
    setup_cloned_repo

    pushd "test-repo" >/dev/null
    run "$GIT_EXPRESS_PATH" remove "../non-existent-worktree"
    popd >/dev/null

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

    # Check it's still listed by git
    pushd "test-repo" >/dev/null
    git_output_before=$(git worktree list)
    [[ "$git_output_before" == *"test-repo.simple-branch"* ]]

    # Run remove command
    run "$GIT_EXPRESS_PATH" remove "../test-repo.simple-branch"
    popd >/dev/null

    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Warning: Worktree path '../test-repo.simple-branch' does not exist."* ]]
    [[ "$output" == *"Removing worktree '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]

    # Check git knows it's gone
    pushd "test-repo" >/dev/null
    git_output_after=$(git worktree list)
    popd >/dev/null
    [[ ! "$git_output_after" == *"test-repo.simple-branch"* ]]
}


@test "remove: fails if path exists but is not a registered worktree" {
    setup_cloned_repo
    # Create a directory that looks like a worktree but isn't registered
    mkdir "../test-repo.fake-worktree"
    touch "../test-repo.fake-worktree/somefile.txt"

    pushd "test-repo" >/dev/null
    run "$GIT_EXPRESS_PATH" remove "../test-repo.fake-worktree"
    popd >/dev/null

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: '../test-repo.fake-worktree' exists but is not a registered git worktree for this repository."* ]]
    # Cleanup the fake directory
    rm -rf "../test-repo.fake-worktree"
}


@test "remove: fails if attempting to remove the main (dynamic) worktree" {
    setup_cloned_repo # Creates test-repo (dynamic) and test-repo.main (static)

    # Try to remove the dynamic worktree ('test-repo') from within itself
    pushd "test-repo" >/dev/null
    run "$GIT_EXPRESS_PATH" remove "." # '.' refers to the dynamic worktree here
    popd >/dev/null

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

    pushd "test-repo" >/dev/null
    run "$GIT_EXPRESS_PATH" remove "../test-repo.simple-branch"
    popd >/dev/null

    echo "$output"
    [ "$status" -ne 0 ]
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

    pushd "test-repo" >/dev/null
    run "$GIT_EXPRESS_PATH" remove --force "../test-repo.simple-branch"
    popd >/dev/null

    echo "$output"
    [ "$status" -eq 0 ]
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

    pushd "test-repo" >/dev/null
    run "$GIT_EXPRESS_PATH" remove -f "../test-repo.simple-branch"
    popd >/dev/null

    echo "$output"
    [ "$status" -eq 0 ]
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

    pushd "test-repo" >/dev/null
    # Use --quiet for the remove command
    run "$GIT_EXPRESS_PATH" remove -q "../test-repo.simple-branch"
    popd >/dev/null

    echo "Output: $output" # Should be empty or only contain git errors if any
    [ "$status" -eq 0 ]
    [ ! -d "../test-repo.simple-branch" ]
    # Check that git-express informational output is suppressed
    [[ ! "$output" == *"Removing worktree"* ]]
    [[ ! "$output" == *"Worktree removed successfully."* ]]
    [[ ! "$output" == *"git-express remove complete"* ]]
    # Check that git's output is also suppressed (git worktree remove is usually quiet on success anyway)
}
