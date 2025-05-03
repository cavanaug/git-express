#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- Prune Command Tests ---

@test "prune: successfully prunes stale worktree registrations" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    
    # Manually remove the directory, leaving the git entry stale
    rm -rf "../test-repo.simple-branch"
    [ ! -d "../test-repo.simple-branch" ]
    
    # Check it's still listed by git
    git_output_before=$(git worktree list)
    [[ "$git_output_before" == *"test-repo.simple-branch"* ]]
    
    # Run prune command
    run "$GIT_EXPRESS_PATH" prune
    
    echo "$output"
    [ "$status" -eq 0 ]
    
    # Check git no longer lists the stale entry
    git_output_after=$(git worktree list)
    [[ ! "$git_output_after" == *"test-repo.simple-branch"* ]]
}

@test "prune: passes options to git worktree prune" {
    setup_cloned_repo
    "$GIT_EXPRESS_PATH" add -q simple-branch
    [ -d "../test-repo.simple-branch" ]
    
    # Manually remove the directory, leaving the git entry stale
    rm -rf "../test-repo.simple-branch"
    [ ! -d "../test-repo.simple-branch" ]
    
    # Run prune command with --verbose option
    run "$GIT_EXPRESS_PATH" prune --verbose
    
    echo "$output"
    [ "$status" -eq 0 ]
    
    # Check git no longer lists the stale entry
    git_output_after=$(git worktree list)
    [[ ! "$git_output_after" == *"test-repo.simple-branch"* ]]
}

@test "prune: fails if not inside a git repository" {
    # Run from the main test temp dir, not inside a repo clone
    run "$GIT_EXPRESS_PATH" prune
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Not inside a git repository or worktree."* ]]
}
