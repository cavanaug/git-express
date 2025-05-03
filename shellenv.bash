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
            echo "Changing directory to worktree for branch '$target_branch': $worktree_path"
            cd "$worktree_path" || return 1 # cd and check for errors
        else
            echo "Error: Found worktree entry for '$target_branch', but directory does not exist: $worktree_path" >&2
            cd "$current_dir" # Go back to original dir
            return 1
        fi
    else
        echo "Error: No worktree found for branch '$target_branch'." >&2
        # Check if it's the main worktree's current branch
        local main_worktree_path=$(git rev-parse --show-toplevel)
        local current_branch_in_main=$(git -C "$main_worktree_path" branch --show-current)
        if [ "$current_branch_in_main" == "$target_branch" ]; then
             echo "Branch '$target_branch' is active in the main worktree ('dynamic view'): $main_worktree_path"
             echo "Changing directory to main worktree."
             cd "$main_worktree_path" || return 1
        else
             cd "$current_dir" # Go back to original dir
             return 1
        fi
    fi

    return 0
}

# Example of how to add more functions:
# my-other-function() {
#   echo "Another function"
# }

# You can add aliases here too if preferred:
# alias gcw='gx-cw'
