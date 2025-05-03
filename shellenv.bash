#!/bin/bash

# This file is intended to be sourced into your shell environment, e.g.,
# source /path/to/shellenv.bash
#
# It provides helper functions for navigating git-express worktrees.

# Function to change directory to the worktree associated with a specific branch.
# Usage: gx-cw <branch-name>
gx-cw() {
    local target_branch="$1"
    local worktree_path=""
    local current_dir=$(pwd) # Remember current directory in case of failure

    if [ -z "$target_branch" ]; then
        echo "Usage: gx-cw <branch-name>" >&2
        return 1
    fi

    # Check if we are inside a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Error: Not inside a git repository or worktree." >&2
        return 1
    fi

    # Use git worktree list and parse the output
    # Format: <path> <short-commit> <branch>
    # We need to handle detached HEAD states as well, though gx convention avoids this for named worktrees.
    while IFS= read -r line; do
        # Extract path and branch info
        local path=$(echo "$line" | awk '{print $1}')
        local branch_info=$(echo "$line" | awk '{print $3}') # Might be [<branch>] or (detached HEAD)

        # Clean up branch info (remove brackets)
        local branch=${branch_info//[\[\]]/}

        if [ "$branch" == "$target_branch" ]; then
            worktree_path="$path"
            break
        fi
    done <<< "$(git worktree list)"

    if [ -n "$worktree_path" ]; then
        if [ -d "$worktree_path" ]; then
            # Output the cd command instead of executing it
            # Use printf for safer quoting if paths contain special characters
            printf "cd %q\n" "$worktree_path"
        else
            echo "Error: Found worktree entry for '$target_branch', but directory does not exist: $worktree_path" >&2
            # No cd command to output, return error
            return 1
        fi
    else
        # Check if it's the main worktree's current branch
        local main_worktree_path
        main_worktree_path=$(git rev-parse --show-toplevel)
        if [ -z "$main_worktree_path" ]; then
             echo "Error: Could not determine main worktree path." >&2
             return 1
        fi
        local current_branch_in_main
        current_branch_in_main=$(git -C "$main_worktree_path" branch --show-current 2>/dev/null || true) # Avoid error if no branches yet

        if [ "$current_branch_in_main" == "$target_branch" ]; then
             # Output the cd command for the main worktree
             printf "cd %q\n" "$main_worktree_path"
        else
             echo "Error: No worktree found for branch '$target_branch'." >&2
             # Also check if the target branch exists at all, maybe? For now, just error.
             return 1
        fi
    fi

    return 0 # Success means we printed a cd command
}

# Example of how to add more functions:
# my-other-function() {
#   echo "Another function"
# }

# You can add aliases here too if preferred:
# alias gcw='gx-cw'
