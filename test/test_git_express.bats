#!/usr/bin/env bats

# Make the script accessible if running tests from the root directory
GIT_EXPRESS_PATH="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/git-express"
TEST_TEMP_DIR="" # Will be set in setup

# --- Test Setup ---

# Store original env vars to restore later
_OLD_GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL:-}"
_OLD_GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-}"
_OLD_GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-}"
_OLD_GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-}"
_OLD_GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-}"
TEMP_GIT_CONFIG="" # Will be set in setup_file

setup_file() {
    # Create a temporary, isolated global git config
    TEMP_GIT_CONFIG=$(mktemp "${BATS_TMPDIR}/test_git_config_XXXXXX")
    export GIT_CONFIG_GLOBAL="$TEMP_GIT_CONFIG"
    # Set default branch name to avoid warnings/differences between git versions
    git config --global init.defaultBranch main
    # Set user details via env vars to bypass local config and GPG signing
    export GIT_AUTHOR_NAME="Test Author"
    export GIT_AUTHOR_EMAIL="test@example.com"
    export GIT_COMMITTER_NAME="Test Committer"
    export GIT_COMMITTER_EMAIL="test@example.com"

    # Create a dummy bare remote repository for clone tests
    export REMOTE_REPO_PATH="${BATS_TMPDIR}/remote_repo.git"
    # Use --initial-branch=main for consistency if git version supports it, otherwise rely on global config
    git init --bare "$REMOTE_REPO_PATH" # init.defaultBranch should handle the name

    # Create initial commit and branches in a temporary clone
    local temp_clone_path="${BATS_TMPDIR}/remote_repo_setup"
    # Ensure the temp clone path is clean before cloning
    rm -rf "$temp_clone_path"
    git clone "$REMOTE_REPO_PATH" "$temp_clone_path"
    pushd "$temp_clone_path" > /dev/null
    # No need for local git config user.* here, env vars handle it
    echo "Initial commit" > README.md
    git add README.md
    # Commit signing should be bypassed due to env vars / lack of GPG config in temp global
    git commit -m "Initial commit"
    git push origin main

    # Create another branch
    git checkout -b feature/test-branch
    echo "Feature content" > feature.txt
    git add feature.txt
    git commit -m "Add feature"
    git push origin feature/test-branch

    # Create a simple branch
    git checkout -b simple-branch
    echo "Simple content" > simple.txt
    git add simple.txt
    git commit -m "Add simple"
    git push origin simple-branch

    # Go back to main
    git checkout main
    popd > /dev/null
    rm -rf "$temp_clone_path"

    echo "Setup remote repo at $REMOTE_REPO_PATH"
}

teardown_file() {
    # Clean up the dummy remote repository
    if [ -d "$REMOTE_REPO_PATH" ]; then
        rm -rf "$REMOTE_REPO_PATH"
        echo "Cleaned up remote repo at $REMOTE_REPO_PATH"
    fi

    # Clean up the temporary global git config and restore env vars
    if [ -f "$TEMP_GIT_CONFIG" ]; then
        rm -f "$TEMP_GIT_CONFIG"
        echo "Cleaned up temp git config $TEMP_GIT_CONFIG"
    fi
    export GIT_CONFIG_GLOBAL="$_OLD_GIT_CONFIG_GLOBAL"
    export GIT_AUTHOR_NAME="$_OLD_GIT_AUTHOR_NAME"
    export GIT_AUTHOR_EMAIL="$_OLD_GIT_AUTHOR_EMAIL"
    export GIT_COMMITTER_NAME="$_OLD_GIT_COMMITTER_NAME"
    export GIT_COMMITTER_EMAIL="$_OLD_GIT_COMMITTER_EMAIL"
    # Unset if they were originally empty
    [ -z "$_OLD_GIT_CONFIG_GLOBAL" ] && unset GIT_CONFIG_GLOBAL
    [ -z "$_OLD_GIT_AUTHOR_NAME" ] && unset GIT_AUTHOR_NAME
    [ -z "$_OLD_GIT_AUTHOR_EMAIL" ] && unset GIT_AUTHOR_EMAIL
    [ -z "$_OLD_GIT_COMMITTER_NAME" ] && unset GIT_COMMITTER_NAME
    [ -z "$_OLD_GIT_COMMITTER_EMAIL" ] && unset GIT_COMMITTER_EMAIL
}

setup() {
    # Create a temporary directory for each test
    TEST_TEMP_DIR=$(mktemp -d "${BATS_TMPDIR}/git_express_test_XXXXXX")
    cd "$TEST_TEMP_DIR"
    # Ensure the script is executable (redundant if done once, but safe)
    chmod +x "$GIT_EXPRESS_PATH"
    echo "Running test in $TEST_TEMP_DIR"
}

teardown() {
    # Clean up the temporary directory
    if [ -d "$TEST_TEMP_DIR" ]; then
        # Go back to original dir in case test failed inside temp dir
        cd "${BATS_TEST_DIRNAME}" || exit 1
        # Force remove the temp dir and its contents
        rm -rf "$TEST_TEMP_DIR"
        echo "Cleaned up test directory $TEST_TEMP_DIR"
    fi
}


# --- Basic Usage Tests ---

@test "git-express with no arguments shows usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone <repository> [<directory>]"* ]]
}


# --- Clone Command Tests ---

@test "git-express clone: basic clone with default branch" {
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

@test "git-express clone: clone with specified directory name" {
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

@test "git-express clone: clone with -b specific branch" {
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

@test "git-express clone: clone with -b branch-with-slash" {
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

@test "git-express clone: clone with -q quiet mode" {
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

@test "git-express clone: fails with missing repository argument" {
    run "$GIT_EXPRESS_PATH" clone
    echo "$output"
    [ "$status" -ne 0 ] # Should fail
    [[ "$output" == *"Error: Missing repository argument for clone command."* ]]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
}


# --- New Command Tests ---

# Helper function to setup a basic cloned repo for 'new' tests
setup_for_new_tests() {
    "$GIT_EXPRESS_PATH" clone -q "$REMOTE_REPO_PATH" test-repo
    # Need to be inside a worktree for 'new' command to work
    cd test-repo
    # Ensure main static worktree exists from clone
    [ -d "../test-repo.main" ]
}

@test "git-express new: create worktree for existing branch" {
    setup_for_new_tests
    # 'simple-branch' exists in the remote repo setup
    run "$GIT_EXPRESS_PATH" new simple-branch
    echo "$output"
    [ "$status" -eq 0 ]
    [ -d "../test-repo.simple-branch" ]
    [ -f "../test-repo.simple-branch/simple.txt" ]
    branch_in_static=$(git -C "../test-repo.simple-branch" branch --show-current)
    [ "$branch_in_static" = "simple-branch" ]
    [[ "$output" == *"Creating worktree for branch 'simple-branch'"* ]]
    [[ "$output" == *"Worktree created for existing branch 'simple-branch'."* ]]
    [[ "$output" == *"git-express new complete for test-repo.simple-branch"* ]]
}

@test "git-express new: create worktree and new branch" {
    setup_for_new_tests
    run "$GIT_EXPRESS_PATH" new my-new-feature
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
    [[ "$output" == *"git-express new complete for test-repo.my-new-feature"* ]]
}

@test "git-express new: create worktree for new branch with slash" {
    setup_for_new_tests
    run "$GIT_EXPRESS_PATH" new feature/another-one
    echo "$output"
    [ "$status" -eq 0 ]
    [ -d "../test-repo.feature-another-one" ]
    [ -f "../test-repo.feature-another-one/README.md" ] # Based on main
    branch_in_static=$(git -C "../test-repo.feature-another-one" branch --show-current)
    [ "$branch_in_static" = "feature/another-one" ]
    git show-ref --verify --quiet "refs/heads/feature/another-one"
    [ "$?" -eq 0 ]
    [[ "$output" == *"git-express new complete for test-repo.feature-another-one"* ]]
}

@test "git-express new: fails if branch name is missing" {
    setup_for_new_tests
    run "$GIT_EXPRESS_PATH" new
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Missing branch name for 'new' command."* ]]
}

@test "git-express new: fails if worktree directory already exists" {
    setup_for_new_tests
    # Create for 'simple-branch' first
    "$GIT_EXPRESS_PATH" new -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    # Try to create it again
    run "$GIT_EXPRESS_PATH" new simple-branch
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Target worktree directory '../test-repo.simple-branch' already exists."* ]]
}

@test "git-express new: fails if not inside a git repository" {
    # Run from the main test temp dir, not inside a repo clone
    run "$GIT_EXPRESS_PATH" new some-branch
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Not inside a git repository or worktree."* ]]
}

@test "git-express new: passes options to git worktree add (e.g., --quiet)" {
    setup_for_new_tests
    # Use --quiet, which should suppress git's output during worktree add
    run "$GIT_EXPRESS_PATH" new --quiet my-quiet-branch
    echo "Output: $output" # Should only contain git-express messages
    [ "$status" -eq 0 ]
    [ -d "../test-repo.my-quiet-branch" ]
    # Check that git's "Preparing worktree" messages are absent
    [[ ! "$output" == *"Preparing worktree"* ]]
    [[ ! "$output" == *"HEAD is now at"* ]]
    # Check that git-express messages are still present
    [[ "$output" == *"Creating worktree for branch 'my-quiet-branch'"* ]]
    [[ "$output" == *"git-express new complete for test-repo.my-quiet-branch"* ]]
}

@test "git-express clone: fails with non-existent branch using -b" {
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

# Add more tests for other options or edge cases if needed

@test "git-express --help shows usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH" --help
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone <repository> [<directory>]"* ]]
}

@test "git-express -h shows usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH" -h
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone <repository> [<directory>]"* ]]
}

@test "git-express with unknown command shows error and usage" {
    run "$GIT_EXPRESS_PATH" unknown-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Unknown command 'unknown-command'"* ]]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
}
