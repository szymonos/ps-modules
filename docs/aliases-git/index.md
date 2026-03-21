# :material-git: aliases-git

Short alias functions for git and GitHub CLI commands. Each alias prints the executed command in
magenta before running it, so you always know what's happening under the hood. All aliases support
`-WhatIf` (print without executing) and `-Quiet` (execute without printing).

!!! note "Module Info"
    **Version:** 1.22.0 &middot; **PowerShell:** 7.0+ &middot; **Dependencies:** none

```powershell
./module_manage.ps1 'aliases-git' -CleanUp
```

## :material-star: Highlights

- **Composable naming** - aliases follow a consistent pattern (`g` + command + modifier),
  e.g. `gacp` = add all + commit + push, `gcan!` = commit --all --no-edit --amend.
- **Smart branch switching** - `gsw` resolves branches by prefix and falls back to
  the default branch when no argument is given.
- **Fetch + sync helpers** - `gmgo` and `grbo` fetch from origin, merge/rebase,
  and push automatically if the operation is clean.
- **Bulk repo management** - `grunrefresh` refreshes all repos under a directory
  (fetch, switch to default branch, merge, prune).
- **Tab completion** - completers for branch names and stash entries across 18 aliases.
- **GitHub CLI coverage** - aliases for issues, PRs, runs, and repo operations.

## :material-book-open-variant: Pages

- :material-format-letter-case: [Naming Conventions](conventions.md) - alias pattern breakdown for git and gh
- :material-source-branch: [Git Aliases](git-aliases.md) - core git command aliases
  (add, branch, commit, diff, fetch, log, push, reset, etc.)
- :octicons-mark-github-16: [GitHub CLI Aliases](gh-aliases.md) - `gh` command aliases
  (browse, issues, PRs, repos, runs, status)
- :material-tools: [Helpers](helpers.md) - branch delete, merge/rebase, switch, stash, and repo management helpers
- :material-text-search: [Log Helpers](log.md) - git log as PowerShell objects, colored output, and grep
- :material-tab: [Completers](completers.md) - tab-completion for branches and stash entries
