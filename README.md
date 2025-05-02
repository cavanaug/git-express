# git-express

An express mechanism for utilizing git branches and worktrees in a sane and flexible manner

## git-express commands

### clone

git-express clone <repository> [<directory>]

- all options passed to git-express clone will be passed to git clone unchecked (you can break things using options that are not compatible with git-express design)
- first create the dynamic view by executing a git clone
- second create a forced named worktree for the default branch using name <repository-name>.<branch-name>

## layout structure

This is an example directory layout for worktrees for 2 repos.

The naming convention is '<<repo-name>>.<<branch-name>' with the 'branch-name' flattened by replacing any directory markers '/' with a '-'

```text

.
├── git-express                   <--  "dynamic" view that allows "git switch"
│   └── .git                      <--  git base directory that is shared acress all worktrees for git-express
│   └── README.md
├── git-express.branch1           <--  "static" view/worktree for branch "branch1" that disallows "git switch"
│   └── README.md
├── git-express.main              <--  "static" view/worktree for branch "main" that disallows "git switch"
│   └── README.md
├── git-express.sandbox-foo       <--  "static" view/worktree for branch "sandbox/foo" that disallows "git switch"
│   └── README.md
│
├── another_git_repo              <--  "dynamic" view that allows "git switch"
├── another_git_repo.main         <--  "static" view/worktree for branch "main" that disallows "git switch"
├── another_git_repo.branch1      <--  "static" view/worktree for branch "branch1" that disallows "git switch"
```

Notes

- PRO: Pretty simple to understand, close alignment with standard git
- NEU: Branch names such as "sandbox/foo" are matched to a directory naming "sandbox-foo"
- NEU: This model leans heavily into the use of worktrees for all branches (TBD dynamic view model)
- NEU: Still TBD how best to deal with a dynamic view (perhaps \_dynamic or \_virtual as the virtual branch name)
- PRO: Doesnt need a "gx clone" to create the structure because it mimics default git  behavior
- CON: Would need a gx init or something to go from a generic git repo to making the first worktree

Conclusion:  Viable.  Leaning towards this for initial implementation, but might adopt 3a later.

```
