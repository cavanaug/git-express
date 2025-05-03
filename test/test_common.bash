#!/usr/bin/env bash

# This file is sourced by other BATS tests. It should not be run directly.
# It contains common setup, teardown, variables, and helper functions.

# --- Common Variables ---

# Make the script accessible if running tests from the root directory
export GIT_EXPRESS_PATH="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/git-express"
export TEST_TEMP_DIR="" # Will be set in setup

# Store original env vars to restore later
_OLD_GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL:-}"
_OLD_GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-}"
_OLD_GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-}"
_OLD_GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-}"
_OLD_GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-}"
TEMP_GIT_CONFIG="" # Will be set in setup_file

# --- Test Setup/Teardown ---

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

# --- Helper Functions ---

# Helper function to setup a basic cloned repo for tests needing an existing repo
# Usage: setup_cloned_repo [repo_name]
# Defaults repo_name to "test-repo" if not provided
setup_cloned_repo() {
    local repo_name="${1:-test-repo}"
    "$GIT_EXPRESS_PATH" clone -q "$REMOTE_REPO_PATH" "$repo_name"
    # Need to be inside a worktree for some commands to work
    cd "$repo_name"
    # Ensure main static worktree exists from clone
    [ -d "../${repo_name}.main" ]
}
