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
    # Use run bash -c '...' to avoid issues with globbing/whitespace in bats checks
    run bash -c "[[ \$(echo \$'${output}') == *'* main (dynamic)'* ]]" # Check dynamic line with asterisk
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'  main '* ]]" # Check static line
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$main_wt_path'* ]]" # Check dynamic path
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$static_wt_path'* ]]" # Check static path
    [ "$status" -eq 0 ]
    # Ensure static line doesn't have (dynamic)
    run bash -c "[[ \$(echo \$'${output}') != *'  main (dynamic)'* ]]"
    [ "$status" -eq 0 ]


    # Run list from inside the static worktree
    cd "../list-repo.main" # cd from list-repo
    run "$GIT_EXPRESS_PATH" list
    echo "$output"
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'  main (dynamic)'* ]]" # Check dynamic line
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'* main '* ]]" # Check static line with asterisk
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$main_wt_path'* ]]" # Check dynamic path
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$static_wt_path'* ]]" # Check static path
    [ "$status" -eq 0 ]
    # Ensure static line doesn't have (dynamic)
    run bash -c "[[ \$(echo \$'${output}') != *'* main (dynamic)'* ]]"
    [ "$status" -eq 0 ]
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

    # Check presence of all entries (order might vary) - Use run bash -c for robustness
    run bash -c "[[ \$(echo \$'${output}') == *'* main (dynamic)'* ]]" # Dynamic with asterisk
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'  main '* && \$(echo \$'${output}') != *'  main (dynamic)'* ]]" # Static main
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'  simple-branch '* ]]" # Static simple
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'  feature/test-branch '* ]]" # Static feature
    [ "$status" -eq 0 ]
    # Check paths are present
    run bash -c "[[ \$(echo \$'${output}') == *'$main_wt_path'* ]]"
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$static_main_path'* ]]"
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$static_simple_path'* ]]"
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$static_feature_path'* ]]"
    [ "$status" -eq 0 ]


    # Check current marker when inside another one
    cd "../$static_simple_path" # cd from list-repo-multi
    run "$GIT_EXPRESS_PATH" list
    echo "$output"
    [ "$status" -eq 0 ]
    # Check presence of all entries (order might vary) - Use run bash -c for robustness
    run bash -c "[[ \$(echo \$'${output}') == *'  main (dynamic)'* ]]" # Dynamic
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'  main '* && \$(echo \$'${output}') != *'  main (dynamic)'* ]]" # Static main
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'* simple-branch '* ]]" # Static simple with asterisk
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'  feature/test-branch '* ]]" # Static feature
    [ "$status" -eq 0 ]
     # Check paths are present
    run bash -c "[[ \$(echo \$'${output}') == *'$main_wt_path'* ]]"
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$static_main_path'* ]]"
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$static_simple_path'* ]]"
    [ "$status" -eq 0 ]
    run bash -c "[[ \$(echo \$'${output}') == *'$static_feature_path'* ]]"
    [ "$status" -eq 0 ]
}

@test "list: fails if not inside a git repository" {
    # Run from the main test temp dir before any clone
    run "$GIT_EXPRESS_PATH" list
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Not inside a git repository or worktree."* ]]
}
