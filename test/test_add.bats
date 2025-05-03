#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- Add Command Tests ---

@test "add: create worktree for existing branch" {
    setup_cloned_repo # Uses default name "test-repo"
    # 'simple-branch' exists in the remote repo setup
    run "$GIT_EXPRESS_PATH" add simple-branch
    echo "$output"
    [ "$status" -eq 0 ]
    [ -d "../test-repo.simple-branch" ]
    [ -f "../test-repo.simple-branch/simple.txt" ]
    branch_in_static=$(git -C "../test-repo.simple-branch" branch --show-current)
    [ "$branch_in_static" = "simple-branch" ]
    [[ "$output" == *"Creating worktree for branch 'simple-branch'"* ]]
    [[ "$output" == *"Worktree created for existing branch 'simple-branch'."* ]]
    [[ "$output" == *"git-express add complete for test-repo.simple-branch"* ]]
}

@test "add: create worktree and new branch" {
    setup_cloned_repo
    run "$GIT_EXPRESS_PATH" add my-new-feature
    echo "$output"
    [ "$status" -eq 0 ]
    [ -d "../test-repo.my-new-feature" ]
    # New branch is based on current HEAD (main), so should have README.md
    [ -f "../test-repo.my-new-feature/README.md" ]
    branch_in_static=$(git -C "../test-repo.my-new-feature" branch --show-current)
    [ "$branch_in_static" = "my-new-feature" ]
    # Verify the branch was actually created in the repo
    git show-ref --verify --quiet "refs/heads/my-new-feature"
    [ "$?" -eq 0 ]
    [[ "$output" == *"Creating worktree for branch 'my-new-feature'"* ]]
    [[ "$output" == *"Branch 'my-new-feature' does not exist. Creating new branch and worktree..."* ]]
    [[ "$output" == *"New branch 'my-new-feature' and worktree created."* ]]
    [[ "$output" == *"git-express add complete for test-repo.my-new-feature"* ]]
}

@test "add: create worktree for new branch with slash" {
    setup_cloned_repo
    run "$GIT_EXPRESS_PATH" add feature/another-one
    echo "$output"
    [ "$status" -eq 0 ]
    [ -d "../test-repo.feature-another-one" ]
    [ -f "../test-repo.feature-another-one/README.md" ] # Based on main
    branch_in_static=$(git -C "../test-repo.feature-another-one" branch --show-current)
    [ "$branch_in_static" = "feature/another-one" ]
    git show-ref --verify --quiet "refs/heads/feature/another-one"
    [ "$?" -eq 0 ]
    [[ "$output" == *"git-express add complete for test-repo.feature-another-one"* ]]
}

@test "add: fails if branch name is missing" {
    setup_cloned_repo
    run "$GIT_EXPRESS_PATH" add
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Missing branch name for 'add' command."* ]]
}

@test "add: fails if worktree directory already exists" {
    setup_cloned_repo
    # Create for 'simple-branch' first
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    # Try to create it again
    run "$GIT_EXPRESS_PATH" add simple-branch
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Target worktree directory '../test-repo.simple-branch' already exists."* ]]
}

@test "add: fails if not inside a git repository" {
    # Run from the main test temp dir, not inside a repo clone
    run "$GIT_EXPRESS_PATH" add some-branch
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Not inside a git repository or worktree."* ]]
}

@test "add: passes options to git worktree add (e.g., --quiet)" {
    setup_cloned_repo
    # Use --quiet, which should suppress git's output during worktree add
    run "$GIT_EXPRESS_PATH" add --quiet my-quiet-branch
    echo "Output: $output" # Should only contain git-express messages
    [ "$status" -eq 0 ]
    [ -d "../test-repo.my-quiet-branch" ]
    # Check that git's "Preparing worktree" messages are absent
    [[ ! "$output" == *"Preparing worktree"* ]]
    [[ ! "$output" == *"HEAD is now at"* ]]
    # Check that git-express informational messages are suppressed
    [[ ! "$output" == *"Creating worktree for branch"* ]]
    [[ ! "$output" == *"Branch 'my-quiet-branch' does not exist."* ]]
    [[ ! "$output" == *"New branch 'my-quiet-branch' and worktree created."* ]]
    [[ ! "$output" == *"git-express add complete"* ]]
}
