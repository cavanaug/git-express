#!/usr/bin/env bats

# Load common setup, variables, and helpers
load 'test_common.bash'

# --- List Command Tests ---

@test "list: basic listing after clone" {
    setup_cloned_repo "list-repo" # Use specific name for clarity
    # setup_cloned_repo leaves us inside the dynamic worktree (list-repo)
    run "$GIT_EXPRESS_PATH" list
    echo "$output"
    [ "$status" -eq 0 ]
    # Should list the main dynamic worktree and the default static one
    # Current directory is the dynamic worktree, so '*' expected there
    # Paths need to be absolute for comparison
    local main_wt_path="$TEST_TEMP_DIR/list-repo"
    local static_wt_path="$TEST_TEMP_DIR/list-repo.main"
    # Check dynamic line (current)
    # Match prefix "* ", branch "main (dynamic)", padding, and path
    [[ "$output" =~ ^\*\ main\ \(dynamic\)[[:space:]]+${main_wt_path}$ ]]

    # Check static line
    # Match prefix "  ", branch "main", padding, and path
    [[ "$output" =~ ^\ \ \ main[[:space:]]+${static_wt_path}$ ]]


    # Run list from inside the static worktree
    cd "../list-repo.main" # cd from list-repo
    run "$GIT_EXPRESS_PATH" list
    echo "$output"
    [ "$status" -eq 0 ]
    # Check dynamic line
    # Match prefix "  ", branch "main (dynamic)", padding, and path
    [[ "$output" =~ ^\ \ \ main\ \(dynamic\)[[:space:]]+${main_wt_path}$ ]]

    # Check static line (current)
    # Match prefix "* ", branch "main", padding, and path
    [[ "$output" =~ ^\*\ main[[:space:]]+${static_wt_path}$ ]]
}

@test "list: listing after adding more worktrees" {
    setup_cloned_repo "list-repo-multi"
    # setup_cloned_repo leaves us inside the dynamic worktree (list-repo-multi)
    "$GIT_EXPRESS_PATH" add -q simple-branch
    "$GIT_EXPRESS_PATH" add -q feature/test-branch
    # Stay inside list-repo-multi (dynamic worktree)

    run "$GIT_EXPRESS_PATH" list
    echo "$output"
    [ "$status" -eq 0 ]
    local main_wt_path="$TEST_TEMP_DIR/list-repo-multi"
    local static_main_path="$TEST_TEMP_DIR/list-repo-multi.main"
    local static_simple_path="$TEST_TEMP_DIR/list-repo-multi.simple-branch"
    local static_feature_path="$TEST_TEMP_DIR/list-repo-multi.feature-test-branch"

    # Check presence of all entries (order might vary)
    # Dynamic (current)
    [[ "$output" =~ ^\*\ main\ \(dynamic\)[[:space:]]+${main_wt_path}$ ]] || fail "Dynamic line incorrect"
    # Static main
    [[ "$output" =~ ^\ \ \ main[[:space:]]+${static_main_path}$ ]] || fail "Static main line incorrect"
    # Static simple
    [[ "$output" =~ ^\ \ \ simple-branch[[:space:]]+${static_simple_path}$ ]] || fail "Static simple line incorrect"
    # Static feature
    [[ "$output" =~ ^\ \ \ feature/test-branch[[:space:]]+${static_feature_path}$ ]] || fail "Static feature line incorrect"


    # Check current marker when inside another one
    cd "../$static_simple_path" # cd from list-repo-multi
    run "$GIT_EXPRESS_PATH" list
    echo "$output"
    [ "$status" -eq 0 ]
    # Check presence of all entries (order might vary)
    # Dynamic
    [[ "$output" =~ ^\ \ \ main\ \(dynamic\)[[:space:]]+${main_wt_path}$ ]] || fail "Dynamic line incorrect (static context)"
    # Static main
    [[ "$output" =~ ^\ \ \ main[[:space:]]+${static_main_path}$ ]] || fail "Static main line incorrect (static context)"
    # Static simple (current)
    [[ "$output" =~ ^\*\ simple-branch[[:space:]]+${static_simple_path}$ ]] || fail "Static simple line incorrect (static context)"
    # Static feature
    [[ "$output" =~ ^\ \ \ feature/test-branch[[:space:]]+${static_feature_path}$ ]] || fail "Static feature line incorrect (static context)"
}

@test "list: fails if not inside a git repository" {
    # Run from the main test temp dir before any clone
    run "$GIT_EXPRESS_PATH" list
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Not inside a git repository or worktree."* ]]
}
