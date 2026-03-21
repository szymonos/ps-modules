# :material-tab: Completers

Tab-completion functions from `Functions/completers.ps1` that provide interactive argument
completion for branch names and stash entries.

## :material-source-branch: ArgGitGetBranches

Returns a deduplicated, sorted list of all local and remote branch names (with remote prefixes
stripped). Provides tab-completion for any alias that accepts a branch argument.

**Used by:**

| Alias      | Description                          | Source |
| ---------- | ------------------------------------ | ------ |
| `gpushoat` | push origin --all + --tags           | alias  |
| `gbd`      | Delete local branch                  | helper |
| `gbd!`     | Force delete local branch            | helper |
| `gbdo`     | Delete local and remote branch       | helper |
| `gbdo!`    | Force delete local and remote branch | helper |
| `gpushd`   | `git push --delete`                  | helper |
| `gmg`      | Merge resolved branch                | helper |
| `gmgo`     | Fetch + merge + push if clean        | helper |
| `grb`      | Rebase resolved branch               | helper |
| `grbo`     | Fetch + rebase + push if clean       | helper |
| `gmb`      | `git merge-base`                     | helper |
| `grmb`     | Reset to merge-base                  | helper |
| `gsw`      | Switch branch (smart resolve)        | helper |
| `gsw!`     | Switch --force (smart resolve)       | helper |

## :material-tray-full: ArgGitGetStashList

Returns a list of stash entries formatted as `stash@{N}` for tab-completion.

**Used by:**

| Alias    | Description         | Source |
| -------- | ------------------- | ------ |
| `gstaap` | `git stash apply`   | helper |
| `gstad`  | `git stash drop`    | helper |
| `gstas`  | `git stash show`    | helper |
| `gstast` | `git stash show -t` | helper |
