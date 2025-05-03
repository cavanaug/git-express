#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- Clone Command Tests ---

@test "clone: basic clone with default branch" {
    run "$GIT_EXPRESS_PATH" clone "$REMOTE_REPO_PATH"
    echo "$output" # For debugging
    [ "$status" -eq 0 ]
    [ -d "remote_repo" ]
    [ -f "remote_repo/README.md" ]
    [ -d "remote_repo.main" ] # Check in current test dir
    [ -f "remote_repo.main/README.md" ]
    # Verify branch in static worktree
    branch_in_static=$(git -C "remote_repo.main" branch --show-current)
    [ "$branch_in_static" = "main" ]
    # Verify output message
    [[ "$output" == *"git-express clone complete for 'remote_repo'."* ]]
    [[ "$output" == *"git-express worktree complete for remote_repo.main"* ]]
}

@test "clone: clone with specified directory name" {
    run "$GIT_EXPRESS_PATH" clone "$REMOTE_REPO_PATH" my-custom-dir
    echo "$output"
    [ "$status" -eq 0 ]
    [ -d "my-custom-dir" ]
    [ -f "my-custom-dir/README.md" ]
    [ -d "my-custom-dir.main" ] # Check in current test dir
    [ -f "my-custom-dir.main/README.md" ]
    branch_in_static=$(git -C "my-custom-dir.main" branch --show-current)
    [ "$branch_in_static" = "main" ]
    [[ "$output" == *"git-express clone complete for 'my-custom-dir'."* ]]
    [[ "$output" == *"git-express worktree complete for my-custom-dir.main"* ]]
}

@test "clone: clone with -b specific branch" {
    run "$GIT_EXPRESS_PATH" clone -b simple-branch "$REMOTE_REPO_PATH"
    echo "$output"
    [ "$status" -eq 0 ]
    [ -d "remote_repo" ]
    [ -f "remote_repo/README.md" ] # Main worktree checks out default (main) initially
    [ ! -f "remote_repo/simple.txt" ] # Should NOT have simple.txt
    [ -d "remote_repo.simple-branch" ] # Check in current test dir
    [ -f "remote_repo.simple-branch/simple.txt" ] # Static worktree has the specified branch
    [ -f "remote_repo.simple-branch/README.md" ] # Should have main's files as it's an ancestor
    branch_in_static=$(git -C "remote_repo.simple-branch" branch --show-current)
    [ "$branch_in_static" = "simple-branch" ]
    [[ "$output" == *"git-express clone complete for 'remote_repo'."* ]]
    [[ "$output" == *"git-express worktree complete for remote_repo.simple-branch"* ]]
}

@test "clone: clone with -b branch-with-slash" {
    run "$GIT_EXPRESS_PATH" clone -b feature/test-branch "$REMOTE_REPO_PATH" feature-repo
    echo "$output"
    [ "$status" -eq 0 ]
    [ -d "feature-repo" ]
    [ -f "feature-repo/README.md" ] # Main worktree checks out default (main)
    [ -d "feature-repo.feature-test-branch" ] # Check in current test dir
    [ -f "feature-repo.feature-test-branch/feature.txt" ] # Static worktree has the specified branch
    branch_in_static=$(git -C "feature-repo.feature-test-branch" branch --show-current)
    [ "$branch_in_static" = "feature/test-branch" ]
    [[ "$output" == *"git-express clone complete for 'feature-repo'."* ]]
    [[ "$output" == *"git-express worktree complete for feature-repo.feature-test-branch"* ]]
}

@test "clone: clone with -q quiet mode" {
    run "$GIT_EXPRESS_PATH" clone -q "$REMOTE_REPO_PATH" quiet-repo
    echo "Output: $output" # Should be minimal or empty from git-express itself
    [ "$status" -eq 0 ]
    [ -d "quiet-repo" ]
    [ -d "quiet-repo.main" ] # Check in current test dir
    # Check that informational output is suppressed
    [[ ! "$output" == *"Cloning repository"* ]]
    [[ ! "$output" == *"Setting up worktree"* ]]
    [[ ! "$output" == *"Creating static worktree"* ]]
    [[ ! "$output" == *"git-express clone complete"* ]]
    [[ ! "$output" == *"git-express worktree complete"* ]]
    # Underlying git clone might still output errors to stderr if any
}

@test "clone: fails with missing repository argument" {
    run "$GIT_EXPRESS_PATH" clone
    echo "$output"
    [ "$status" -ne 0 ] # Should fail
    [[ "$output" == *"Error: Missing repository argument for clone command."* ]]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
}

@test "clone: fails with non-existent branch using -b" {
    run "$GIT_EXPRESS_PATH" clone -b non-existent-branch "$REMOTE_REPO_PATH" bad-branch-repo
    echo "$output"
    [ "$status" -ne 0 ] # Should fail
    # Directory might be created by git clone before worktree add fails
    [ -d "bad-branch-repo" ]
    # Check for specific error messages
    [[ "$output" == *"Error: Branch 'non-existent-branch' not found locally or in origin remote."* ]] || \
    [[ "$output" == *"Error: Failed to create worktree for branch 'non-existent-branch'."* ]] # Depending on exact failure point
    # Static worktree should not exist
    [ ! -d "bad-branch-repo.non-existent-branch" ] # Check in current test dir
}
