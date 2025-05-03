#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- Basic Usage Tests ---

@test "git-express with no arguments shows usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone [opts] [-b <branch>] <repo> [<dir>]"* ]]
    [[ "$output" == *"add   [opts] <branch>"* ]]
    [[ "$output" == *"list"* ]]
}

@test "git-express --help shows usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH" --help
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone [opts] [-b <branch>] <repo> [<dir>]"* ]]
    [[ "$output" == *"add   [opts] <branch>"* ]]
    [[ "$output" == *"list"* ]]
}

@test "git-express -h shows usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH" -h
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone [opts] [-b <branch>] <repo> [<dir>]"* ]]
    [[ "$output" == *"add   [opts] <branch>"* ]]
    [[ "$output" == *"list"* ]]
}

@test "git-express with unknown command shows error and usage" {
    run "$GIT_EXPRESS_PATH" unknown-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Unknown command 'unknown-command'"* ]]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
}
