# :material-tools: Helpers

Helper functions from `Functions/helper.ps1` that combine multiple git operations or provide
interactive workflows like branch resolution and remote syncing.

## :material-delete: Branch Delete

| Alias    | Description                          |
| -------- | ------------------------------------ |
| `gbd`    | Delete local branch                  |
| `gbd!`   | Force delete local branch            |
| `gbdo`   | Delete local and remote branch       |
| `gbdo!`  | Force delete local and remote branch |
| `gbdl`   | Remove local branches                |
| `gbdl!`  | Remove local branches (no-merged)    |
| `gbdm`   | Remove merged branches               |
| `gbdm!`  | Remove merged branches (+ remote)    |
| `gpushd` | `git push --delete`                  |

!!! warning
    `gbdo!` and `gbdm!` also delete remote branches - use with caution.

## :material-merge: Merge / Rebase

| Alias  | Description                    |
| ------ | ------------------------------ |
| `gmg`  | Merge resolved branch          |
| `gmgo` | Fetch + merge + push if clean  |
| `grb`  | Rebase resolved branch         |
| `grbo` | Fetch + rebase + push if clean |
| `gmb`  | `git merge-base`               |
| `grmb` | Reset to merge-base            |

## :material-swap-horizontal-bold: Switch

| Alias  | Description                    |
| ------ | ------------------------------ |
| `gsw`  | Switch branch (smart resolve)  |
| `gsw!` | Switch --force (smart resolve) |

## :material-package-down: Stash

| Alias    | Description         |
| -------- | ------------------- |
| `gstaap` | `git stash apply`   |
| `gstad`  | `git stash drop`    |
| `gstas`  | `git stash show`    |
| `gstast` | `git stash show -t` |

## :material-folder-sync: Repo Management

| Alias         | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| `grunrepocmd` | Run a command across multiple repos                                 |
| `grunrefresh` | Refresh all repos (fetch, switch to default branch, merge, cleanup) |
| `gruncfl`     | Set git config --local in all repos                                 |
