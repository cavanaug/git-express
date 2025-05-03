# git-express directory layout

The various layout options considered for git-express.  

Objectives

- support task based branching workflow (task branches MUST branch from a worktree, not a dynamic view)
- coherent directory layout
- maintain flexibility
- support reasonable interop with standard git commands

## Option 1a: Flat layout contained within repo itself, repo root as dynamic view

```text
git-express/
├── .git                          <--  bare git-express repos that is shared for all git-express worktrees
│
├── branch1                       <--  "static" view/worktree for branch "branch1" ("git switch" disallowed)
│   └── README.md
├── main                          <--  "static" view/worktree for branch "main" ("git switch" disallowed)
│   └── README.md
├── sandbox-foo                   <--  "static" view/worktree for branch "sandbox/foo" ("git switch" disallowed)
│   └── README.md
│
└── README.md                     <--  File as part of dynamic view ("git switch" allowed)
    └── README.md
```

Notes

- PRO: Better compatibility with git commands, no need for "gx clone" to create the initial structure
- NEU: Branch names such as "sandbox/foo" are flattened to "sandbox-foo"
- NEU: What to do about naming and a dynamic view?
- CON: Confusing to understand which folders at root are part of repo or are they branches
- CON: Collisions on branch names with directory names in the repo itself
- CON: Needs a "gx clone" to create the structure or multiple git commands
- CON: Dynamic view is pretty ugly

Conclusion:  Rejected

## Option 1b: Flat layout contained within base repo itself

```text
git-express/
├── HEAD
├── branches
├── config
├── description
├── index
├── info
├── logs
├── objects
├── packed-refs
└── refs
│
├── branch1                       <--  "static" view/worktree for branch "branch1" ("git switch" disallowed)
│   └── README.md
├── main                          <--  "static" view/worktree for branch "main" ("git switch" disallowed)
│   └── README.md
├── sandbox-foo                   <--  "static" view/worktree for branch "sandbox/foo" ("git switch" disallowed)
│   └── README.md
```

Notes

- PRO: Better compatibility with git commands, no need for "gx clone" to create the initial structure
- NEU: Branch names such as "sandbox/foo" are flattened to "sandbox-foo"
- CON: Lots of visual noise in terms of extraneous files
- CON: Collisions on branch names with directory names in the base repo itself
- NEU: This model leans heavily into the use of worktrees for all branches (TBD dynamic view model)
- CON: Needs a "gx clone" to create the structure or multiple git commands
- CON: Dynamic view is pretty ugly

Conclusion:  Rejected

## Option 1c: Flat layout contained within repo itself

```text
git-express/
├── .git                          <--  bare git-express repos that is shared for all git-express worktrees
├── branch1                       <--  "static" view/worktree for branch "branch1" ("git switch" disallowed)
│   └── README.md
├── main                          <--  "static" view/worktree for branch "main" ("git switch" disallowed)
│   └── README.md
└── sandbox-foo                   <--  "static" view/worktree for branch "sandbox/foo" ("git switch" disallowed)
    └── README.md
```

Notes

- PRO: Pretty simple to understand
- PRO: Much cleaner & less noise than option 1a or 1b
- NEU: Branch names such as "sandbox/foo" are flattened to "sandbox-foo"
- NEU: This model leans heavily into the use of worktrees for all branches (TBD dynamic view model)
- NEU: Still TBD how best to deal with a dynamic view (perhaps _dynamic_ or _virtual_ as the virtual branch name)
- CON: Needs a "gx clone" to create the structure or multiple git commands

Conclusion:  Not terrible, but not great either

## Option 2: Nested layout contained within repo itself

```text
git-express/
├── .git                          <--   bare git-express repos that is shared for all git-express worktrees
├── branch1                       <--  "static" view/worktree for branch "branch1" ("git switch" disallowed)
│   └── README.md
├── main                          <--  "static" view/worktree for branch "main" ("git switch" disallowed)
│   └── README.md
└── sandbox                       <--  a regular filesystem directory
    └── foo                       <--  "static" view/worktree for branch "sandbox/foo" ("git switch" disallowed)
        └── README.md
```

Notes

- PRO: Pretty simple to understand (some compromises with branch names)
- NEU: Branch names such as "sandbox/foo" are matched to a directory structure "sandbox/foo"
- NEU: This model leans heavily into the use of worktrees for all branches (TBD dynamic view model)
- CON: Worktree name must map to the directory name of "foo", would cause worktree name collisions with "feature/foo"
- CON: Needs a "gx clone" to create the structure or multiple git commands

Conclusion:  Rejected, primarily due to conflicts with directory names for branches and worktree names

## Option 3a: Independent directory per worktree with a hidden multi repo directory to hold each repo bare directory

```text
.
├── .git-bare                     <--  location for all bare repositories
│   └── git-express               <--  bare git-express repos that is shared for all git-express worktrees
│   └── another_git_repo          <--  bare another_git_repo repos that is shared for all git-express worktrees
│
├── git-express.branch1           <--  "static" view/worktree for branch "branch1" ("git switch" disallowed)
│   └── README.md
├── git-express.main              <--  "static" view/worktree for branch "main" ("git switch" disallowed)
│   └── README.md
├── git-express.sandbox-foo       <--  "static" view/worktree for branch "sandbox/foo" ("git switch" disallowed)
│   └── README.md
│
├── another_git_repo.main         <--  "static" view/worktree for branch "main" ("git switch" disallowed)
├── another_git_repo.branch1      <--  "static" view/worktree for branch "branch1" ("git switch" disallowed)
```

Notes

- PRO: Pretty simple to understand
- NEU: Branch names such as "sandbox/foo" are matched to a directory naming "sandbox-foo"
- NEU: .git-bare is an invented convention
- NEU: This model leans heavily into the use of worktrees for all branches (TBD dynamic view model)
- NEU: Still TBD how best to deal with a dynamic view (perhaps \_dynamic or \_virtual as the virtual branch name)
- CON: Needs a "gx clone" to create the structure or multiple git commands
- PRO: Could perhaps generalize the search for .git-bare to allow it to exist in parent, or at $HOME etc

Conclusion:  Viable, will consider this.

## Option 3b: Independent directory per worktree with a hidden per repo bare directory

```text
├── .git-express.bare             <--  bare repos that is shared for all git-express worktrees
├── git-express.branch1           <--  "static" view/worktree for branch "branch1" ("git switch" disallowed)
│   └── README.md
├── git-express.main              <--  "static" view/worktree for branch "main" ("git switch" disallowed)
│   └── README.md
└── git-express.sandbox-foo       <--  "static" view/worktree for branch "sandbox/foo" ("git switch" disallowed)
│   └── README.md
│
├── .another_git_repo.bare        <--  bare repos that is shared for all another_git_repo worktrees
├── another_git_repo.main         <--  "static" view/worktree for branch "main" ("git switch" disallowed)
├── another_git_repo.branch1      <--  "static" view/worktree for branch "branch1" ("git switch" disallowed)
```

Notes

- PRO: Pretty simple to understand
- NEU: Branch names such as "sandbox/foo" are matched to a directory naming "sandbox-foo"
- NEU: .<<repo>>.bare is an invented convention, but has better direct connection to the repo name
- NEU: This model leans heavily into the use of worktrees for all branches (TBD dynamic view model)
- NEU: Still TBD how best to deal with a dynamic view (perhaps \_dynamic or \_virtual as the virtual branch name)
- CON: Needs a "gx clone" to create the structure or multiple git commands

Conclusion:  Rejected, I like 3a better

## Option 3c: Independent directory per worktree with a hidden per repo bare directory

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
