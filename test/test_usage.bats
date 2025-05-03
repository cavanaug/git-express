#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- Basic Usage Tests ---

@test "git-express with no arguments shows general usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"       git-express <command> --help"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone"* ]]
    [[ "$output" == *"add   [opts] <branch>"* ]]
    [[ "$output" == *"list"* ]]
    [[ "$output" == *"remove [opts] <branch-name | worktree-path>"* ]]
}

@test "git-express --help shows general usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH" --help
    [ "$status" -eq 1 ] # Top-level help still exits with 1
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"       git-express <command> --help"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone"* ]]
    [[ "$output" == *"add   [opts] <branch>"* ]]
    [[ "$output" == *"list"* ]]
    [[ "$output" == *"remove [opts] <branch-name | worktree-path>"* ]]
}

@test "git-express -h shows general usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH" -h
    [ "$status" -eq 1 ] # Top-level help still exits with 1
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"       git-express <command> --help"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone"* ]]
    [[ "$output" == *"add   [opts] <branch>"* ]]
    [[ "$output" == *"list"* ]]
    [[ "$output" == *"remove [opts] <branch-name | worktree-path>"* ]]
}

@test "git-express with unknown command shows error and usage" {
    run "$GIT_EXPRESS_PATH" unknown-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Unknown command 'unknown-command'"* ]]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
}

# --- Subcommand Usage Tests ---

@test "usage: clone with no arguments shows usage" {
    run "$GIT_EXPRESS_PATH" clone
    [ "$status" -ne 0 ] # Should fail
    [[ "$output" == *"Error: Missing repository argument for clone command."* ]]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
}

@test "usage: add with no arguments shows usage" {
    # Need to be inside a repo for 'add' to pass initial check, but fail on args
    setup_cloned_repo "usage-test-repo"
    run "$GIT_EXPRESS_PATH" add
    [ "$status" -ne 0 ] # Should fail
    [[ "$output" == *"Error: Missing branch name for 'add' command."* ]]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
}

@test "usage: remove with no arguments shows usage" {
    # Need to be inside a repo for 'remove' to pass initial check, but fail on args
    setup_cloned_repo "usage-test-repo"
    run "$GIT_EXPRESS_PATH" remove
    [ "$status" -ne 0 ] # Should fail
    [[ "$output" == *"Error: Missing required <branch-name | worktree-path> argument for 'remove' command."* ]]
    [[ "$output" == *"Usage: git-express remove [opts] <branch-name | worktree-path>"* ]]
}

# Note: 'list' currently doesn't explicitly check for extra arguments.
# It just runs 'git worktree list --porcelain' regardless.
# If we wanted 'list' to fail with extra args, the script would need modification.
# For now, we test that it runs successfully even with extra args.
@test "usage: list with extra arguments still runs (doesn't show usage)" {
    setup_cloned_repo "usage-test-repo"
    run "$GIT_EXPRESS_PATH" list extra-arg
    [ "$status" -eq 0 ] # Should succeed
    [[ "$output" == *" main (dynamic)"* ]] # Check for expected list output
    [[ ! "$output" == *"Usage: git-express <command> [<args>]"* ]] # Ensure usage is NOT shown
}

# --- Subcommand --help Tests ---

@test "usage: clone --help shows clone usage" {
    run "$GIT_EXPRESS_PATH" clone --help
    [ "$status" -eq 0 ] # Help exits with 0
    [[ "$output" == *"Usage: git-express clone [opts]"* ]] # Check specific clone usage
    [[ "$output" == *"Clone a repository and set up worktrees."* ]]
    [[ ! "$output" == *"Commands:"* ]] # Should not show general command list
}

@test "usage: clone -h shows clone usage" {
    run "$GIT_EXPRESS_PATH" clone -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: git-express clone [opts]"* ]]
    [[ "$output" == *"Clone a repository and set up worktrees."* ]]
}

@test "usage: add --help shows add usage" {
    run "$GIT_EXPRESS_PATH" add --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: git-express add [opts] <branch>"* ]]
    [[ "$output" == *"Create a static worktree for <branch>."* ]]
}

@test "usage: add -h shows add usage" {
    run "$GIT_EXPRESS_PATH" add -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: git-express add [opts] <branch>"* ]]
    [[ "$output" == *"Create a static worktree for <branch>."* ]]
}

@test "usage: list --help shows list usage" {
    run "$GIT_EXPRESS_PATH" list --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: git-express list"* ]]
    [[ "$output" == *"List all worktrees associated"* ]]
}

@test "usage: remove --help shows remove usage" {
    run "$GIT_EXPRESS_PATH" remove --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: git-express remove [opts] <branch-name | worktree-path>"* ]]
    [[ "$output" == *"Remove an existing static git-express worktree, specified by branch name or path."* ]]
}

@test "usage: remove -h shows remove usage" {
    run "$GIT_EXPRESS_PATH" remove -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: git-express remove [opts] <branch-name | worktree-path>"* ]]
    [[ "$output" == *"Remove an existing static git-express worktree, specified by branch name or path."* ]]
}

@test "usage: list -h shows list usage" {
    run "$GIT_EXPRESS_PATH" list -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: git-express list"* ]]
    [[ "$output" == *"List all worktrees associated"* ]]
}
