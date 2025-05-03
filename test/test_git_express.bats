#!/usr/bin/env bats

# Make the script accessible if running tests from the root directory
GIT_EXPRESS_PATH="${BATS_TEST_DIRNAME}/../git-express"

setup() {
    # Ensure the script is executable
    chmod +x "$GIT_EXPRESS_PATH"
}

@test "git-express with no arguments shows usage and exits with status 1" {
    run "$GIT_EXPRESS_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: git-express <command> [<args>]"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"clone <repository> [<directory>]"* ]]
}

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
