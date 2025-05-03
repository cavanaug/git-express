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
    [[ "$output" == *"Removing worktree at '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]
    [[ "$output" == *"git-express remove complete for test-repo.simple-branch"* ]]
}

@test "remove: fails if worktree path does not exist" {
    setup_cloned_repo

    run "$GIT_EXPRESS_PATH" remove "../non-existent-worktree"

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No directory found at '../non-existent-worktree', trying as branch name..."* ]]
    [[ "$output" == *"Error: Branch '../non-existent-worktree' does not exist."* ]]
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
    # Check for the specific error message and prune suggestion
    [[ "$output" == *"Error: Worktree path '../test-repo.simple-branch' does not exist, but a registration was found."* ]]
    [[ "$output" == *"Use 'git worktree prune' to remove stale worktree entries."* ]]

    # Check git *still* lists the stale entry (still in test-repo)
    git_output_after=$(git worktree list)
    [[ "$git_output_after" == *"test-repo.simple-branch"* ]]
}

@test "remove: fails if path exists but is not a git worktree" {
    setup_cloned_repo
    # Create a directory that looks like a worktree but isn't a git worktree
    mkdir -p "../test-repo.fake-worktree"
    touch "../test-repo.fake-worktree/somefile.txt"

    run "$GIT_EXPRESS_PATH" remove "../test-repo.fake-worktree"

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Path '../test-repo.fake-worktree' exists but is not a git worktree."* ]]
    
    # Cleanup the fake directory
    rm -rf "../test-repo.fake-worktree"
}

@test "remove: fails if attempting to remove the main (dynamic) worktree" {
    setup_cloned_repo # Creates test-repo (dynamic) and test-repo.main (static)

    # Try to remove the dynamic worktree ('test-repo') from within itself (already cd'd into it)
    run "$GIT_EXPRESS_PATH" remove "."

    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Cannot remove the main (dynamic) worktree"* ]]
    [[ "$output" == *"git-express only supports removing static worktrees."* ]]
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
    [[ "$output" == *"Removing worktree at '../test-repo.simple-branch'"* ]]
    [[ "$output" == *"Error: Failed to remove worktree at '../test-repo.simple-branch'."* ]]
    [[ "$output" == *"Tip: Use --force (-f) to remove worktrees with uncommitted changes."* ]]
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
    [[ "$output" == *"Force removing worktree at '../test-repo.simple-branch'"* ]]
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
    [[ "$output" == *"Force removing worktree at '../test-repo.simple-branch'"* ]]
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
    [[ "$output" == *"No directory found at 'simple-branch', trying as branch name..."* ]]
    [[ "$output" == *"Looking for worktree at path: ../test-repo.simple-branch"* ]]
    [[ "$output" == *"Removing worktree at '../test-repo.simple-branch'"* ]]
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
    [[ "$output" == *"No directory found at 'feature/test-branch', trying as branch name..."* ]]
    [[ "$output" == *"Looking for worktree at path: ../test-repo.feature-test-branch"* ]]
    [[ "$output" == *"Removing worktree at '../test-repo.feature-test-branch'"* ]]
    [[ "$output" == *"Worktree removed successfully."* ]]
    [[ "$output" == *"git-express remove complete for test-repo.feature-test-branch"* ]]
}

@test "remove: fails if branch name does not exist" {
    setup_cloned_repo
    run "$GIT_EXPRESS_PATH" remove non-existent-branch
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No directory found at 'non-existent-branch', trying as branch name..."* ]]
    [[ "$output" == *"Error: Branch 'non-existent-branch' does not exist."* ]]
}

@test "remove: fails if branch exists but has no corresponding worktree" {
    setup_cloned_repo
    # Create a branch without a worktree
    git branch test-branch-no-worktree
    
    run "$GIT_EXPRESS_PATH" remove test-branch-no-worktree
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No directory found at 'test-branch-no-worktree', trying as branch name..."* ]]
    [[ "$output" == *"Error: No worktree found for branch 'test-branch-no-worktree' at expected path '../test-repo.test-branch-no-worktree'."* ]]
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
    [[ ! "$output" == *"No directory found"* ]]
    [[ ! "$output" == *"Looking for worktree"* ]]
    [[ ! "$output" == *"Removing worktree"* ]]
    [[ ! "$output" == *"Worktree removed successfully."* ]]
    [[ ! "$output" == *"git-express remove complete"* ]]
}
