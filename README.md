# git-express

An opinionated express mechanism for utilizing git branches and worktrees in a sane and flexible manner

## Definitions/Vocabulary

dynamic worktree = worktree that is the "base" for all other worktrees and allows usage of git switch
static worktree =  worktree that with a named "branch" and does not allow usage of git switch
worktree-name (dynamic) = <<repository-name>>
worktree-name (static) = <<repository-name>>.<<branch-flattened>>
branch = any git branch name
branch-flattened = branch name with any directory markers '/' replaced with a '-'

## Subcommands

### git-express clone - Clone repository and create worktree

```text

git-express clone [options] [-b <branch>] <repository> [<directory>]

- <directory> is now the default location for any worktree created by git-express
- Creates git repository in <directory> that serves as the "dynamic worktree"
- Creates git worktree in <directory> using naming of <repository-name>.<branch-flattened>
     if -b branch not specified branch will be the repository HEAD branch

Options:
  -b  <branch>     Specify the branch to check out. If not specified, the HEAD branch will be used.
  [opts]           Other options passed directly to 'git worktree add'.

Note: All [options] passed to git-express clone will be passed internally to git clone unchecked and may break things, use judiciously.
```

### git-express add - Create a worktree and create new branch if needed

```text
git-express add [opts] <branch>

- If the <branch> does not currently exist, a new branch will be created
- Creates git worktree for <branch> using standard naming of <repository-name>.<branch-flattened>

Options:
  [opts]           Other options passed directly to 'git worktree add'.
```

### git-express list - List worktrees

```text
git-express list

- Lists all worktrees associated with the current repository.
- Marks the current worktree with '*'.
- Marks the dynamic worktree with '(dynamic)'.
- Output format: [* ]<branch> [(dynamic)] <path>

Options:
  [opts]           Other options passed directly to 'git worktree list'.
```

### git-express move - Move a worktree to a new location

```text
git-express move <worktree> <new-path>

- Moves an existing static git-express worktree to a new location
- Prevents renaming the worktree itself
- Can be run from outside a git repository when providing a worktree path

Options:
  -q, --quiet      Suppress informational messages.
  [opts]           Other options passed directly to 'git worktree move'.
```

### git-express remove - Remove a static worktree

```text
git-express remove [opts] <branch-name | worktree-path>

- Removes an existing static git-express worktree, specified by branch name or path.
- Uses 'git worktree remove' internally.
- Prevents removing the main (dynamic) worktree.
- If a branch name is given, it finds the corresponding static worktree path (e.g., ../<repo>.<branch>).

Options:
  -f, --force      Force removal even if the worktree has uncommitted changes.
  -q, --quiet      Suppress informational messages.
  [opts]           Other options passed directly to 'git worktree remove'.
```

### git-express prune - Remove stale worktree registrations

```text
git-express prune [opts]

- Removes stale worktree registrations.
- Direct passthrough to 'git worktree prune'.

Options:
  [opts]           All options are passed directly to 'git worktree prune'.
```

### git-express repair - Repair worktree administrative files

```text
git-express repair [opts]

- Repairs worktree administrative files.
- Direct passthrough to 'git worktree repair'.

Options:
  [opts]           All options are passed directly to 'git worktree repair'.
```

## Directory Layout/Structure

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
