#!/bin/bash

# This file is intended to be sourced into your shell environment, e.g.,
# source /path/to/shellenv.bash
#
# It provides helper functions for navigating git-express worktrees.

# Function to change directory to the worktree associated with a specific branch.
# Usage: gx-cw <branch-name>
gx-cw() {
    local target_branch="$1"
    local specific_worktree_path="" # Path matching <repo>.${flattened_branch}
    local main_worktree_path=""     # Path of the main worktree (dynamic view)
    local main_worktree_branch=""   # Branch currently checked out in main worktree
    local current_dir=$(pwd)        # Remember current directory in case of failure

    if [ -z "$target_branch" ]; then
        echo "Usage: gx-cw <branch-name>" >&2
        return 1
    fi

    # Check if we are inside a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Error: Not inside a git repository or worktree." >&2
        return 1
    fi

    # Flatten the target branch name (replace / with -) like in git-express clone
    local flattened_target_branch
    flattened_target_branch=$(echo "$target_branch" | sed 's/\//-/g')
    local expected_suffix=".${flattened_target_branch}"

    # Get main worktree path early
    main_worktree_path=$(git rev-parse --show-toplevel)
    if [ -z "$main_worktree_path" ]; then
         echo "Error: Could not determine main worktree path." >&2
         return 1
    fi
    main_worktree_branch=$(git -C "$main_worktree_path" branch --show-current 2>/dev/null || true)

    # Use git worktree list and parse the output
    # Format: <path> <short-commit> <branch>
    while IFS= read -r line; do
        # Extract path and branch info
        local path
        path=$(echo "$line" | awk '{print $1}')
        local branch_info
        branch_info=$(echo "$line" | awk '{print $3}') # Might be [<branch>] or (detached HEAD)

        # Clean up branch info (remove brackets)
        local branch
        branch=${branch_info//[\[\]]/}

        # Check if this is the specific static worktree we are looking for
        # It must match the branch AND end with the expected suffix
        if [ "$branch" == "$target_branch" ] && [[ "$path" == *"$expected_suffix" ]]; then
            specific_worktree_path="$path"
            break # Found the best match, no need to check further
        fi
    done <<< "$(git worktree list)"

    # --- Decide which path to output ---

    # Priority 1: Specific static worktree path found
    if [ -n "$specific_worktree_path" ]; then
        if [ -d "$specific_worktree_path" ]; then
            printf "cd %q\n" "$specific_worktree_path"
            return 0
        else
            # This case should ideally not happen if git worktree list is accurate
            echo "Error: Found specific worktree entry for '$target_branch', but directory does not exist: $specific_worktree_path" >&2
            return 1
        fi
    fi

    # Priority 2: Target branch is checked out in the main worktree (dynamic view)
    # This check is only relevant if no specific static worktree was found above.
    if [ "$main_worktree_branch" == "$target_branch" ]; then
         if [ -d "$main_worktree_path" ]; then
             printf "cd %q\n" "$main_worktree_path"
             return 0
         else
            # Should not happen if main_worktree_path was determined correctly
            echo "Error: Main worktree directory does not exist: $main_worktree_path" >&2
            return 1
         fi
    fi

    # Error: No suitable worktree found
    echo "Error: No specific worktree ending in '$expected_suffix' found for branch '$target_branch'," >&2
    echo "       and branch '$target_branch' is not the current branch ('$main_worktree_branch') in the main worktree ($main_worktree_path)." >&2
    return 1
}

# Example of how to add more functions:
# my-other-function() {
#   echo "Another function"
# }

# You can add aliases here too if preferred:
# alias gcw='gx-cw'
