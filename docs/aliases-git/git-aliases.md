# :material-source-branch: Git Aliases

Core git command aliases from `Functions/alias.ps1`. Each function wraps a single git command.

## :material-plus: Add

| Alias  | Command            |
| ------ | ------------------ |
| `ga`   | `git add`          |
| `gaa`  | `git add --all`    |
| `gapa` | `git add --patch`  |
| `gau`  | `git add --update` |

## :material-account-search: Blame

| Alias | Command           |
| ----- | ----------------- |
| `gbl` | `git blame -b -w` |

## :material-source-branch: Branch

| Alias  | Command                     |
| ------ | --------------------------- |
| `gb`   | `git branch`                |
| `gba`  | `git branch --all`          |
| `gbnm` | `git branch --no-merged`    |
| `gbr`  | `git branch --remote`       |
| `gbsu` | `git branch --set-upstream` |

## :material-call-split: Bisect

| Alias  | Command            |
| ------ | ------------------ |
| `gbs`  | `git bisect`       |
| `gbsb` | `git bisect bad`   |
| `gbsg` | `git bisect good`  |
| `gbsr` | `git bisect reset` |
| `gbss` | `git bisect start` |

## :material-check: Commit

| Alias     | Command / Description                |
| --------- | ------------------------------------ |
| `gcv`     | `git commit --verbose`               |
| `gc!`     | `git commit --verbose --amend`       |
| `gca`     | `git commit --verbose --all`         |
| `gcap`    | commit all + push                    |
| `gac`     | add all + commit                     |
| `gacp`    | add all + commit + push              |
| `gca!`    | `git commit --verbose --all --amend` |
| `gac!`    | add all + amend                      |
| `gcam`    | `git commit --all -m`                |
| `gcamp`   | commit all -m + push                 |
| `gacm`    | add all + commit -m                  |
| `gacmp`   | add all + commit -m + push           |
| `gcan!`   | commit all --no-edit --amend         |
| `gcanp!`  | commit all --no-edit --amend + push! |
| `gacn!`   | add all + amend --no-edit            |
| `gacnp!`  | add all + amend --no-edit + push!    |
| `gcns!`   | amend --signoff --no-edit            |
| `gcans!`  | commit all --signoff --no-edit amend |
| `gacns!`  | add all + signoff --no-edit amend    |
| `gcmsg`   | `git commit -m`                      |
| `gcmsgp`  | commit -m + push                     |
| `gcempty` | `git commit --allow-empty -m`        |
| `gcn!`    | `git commit --no-edit --amend`       |
| `gcnp!`   | amend --no-edit + push!              |
| `gcsm`    | `git commit --signoff -m`            |

!!! tip
    Aliases ending with `!` use `--force-with-lease` for safe force-pushing.

## :material-fruit-cherries: Cherry-Pick

| Alias  | Command                      |
| ------ | ---------------------------- |
| `gcp`  | `git cherry-pick`            |
| `gcpa` | `git cherry-pick --abort`    |
| `gcpc` | `git cherry-pick --continue` |
| `gcps` | `git cherry-pick --signoff`  |

## :material-swap-horizontal: Checkout

| Alias    | Command            |
| -------- | ------------------ |
| `gco`    | `git checkout`     |
| `gcount` | `git shortlog -sn` |
| `gcd`    | cd to repo root    |

## :material-content-copy: Clone / Clean

| Alias       | Command                 |
| ----------- | ----------------------- |
| `gcl`       | `git clone --recursive` |
| `gclean`    | `git clean --force -d`  |
| `gclean!`   | reset hard + clean      |
| `gpristine` | reset hard + clean -x   |

!!! warning
    `gclean!` and `gpristine` are destructive - they reset and clean the working tree.

## :material-cog: Config

| Alias   | Command                      |
| ------- | ---------------------------- |
| `gcf`   | `git config`                 |
| `gcfg`  | `git config --global`        |
| `gcfge` | `git config --global --edit` |
| `gcfgl` | `git config --global --list` |
| `gcfl`  | `git config --local`         |
| `gcfle` | `git config --local --edit`  |
| `gcfll` | `git config --local --list`  |

## :material-file-compare: Diff

| Alias  | Command                |
| ------ | ---------------------- |
| `gd`   | `git diff`             |
| `gdca` | `git diff --cached`    |
| `gdno` | `git diff --name-only` |
| `gdt`  | `git diff-tree`        |
| `gdw`  | `git diff --word-diff` |
| `gdct` | `git describe --tags`  |

## :material-download: Fetch

| Alias  | Command                             |
| ------ | ----------------------------------- |
| `gf`   | `git fetch`                         |
| `gfa`  | `git fetch --all --prune`           |
| `gfa!` | `git fetch --all --tags -p --force` |
| `gfo`  | `git fetch origin`                  |

## :material-magnify: Grep

| Alias  | Command                         |
| ------ | ------------------------------- |
| `gg`   | `git grep -i`                   |
| `ggc`  | `git gc`                        |
| `ggca` | `git gc --aggressive`           |
| `gge`  | `git grep -i --extended-regexp` |
| `ggp`  | `git grep -i --perl-regexp`     |

## :material-help-circle: Help

| Alias | Command    |
| ----- | ---------- |
| `ghh` | `git help` |

## :material-eye-off: Ignore

| Alias       | Command                                  |
| ----------- | ---------------------------------------- |
| `gignore`   | `git update-index --assume-unchanged`    |
| `gignored`  | list ignored files                       |
| `gunignore` | `git update-index --no-assume-unchanged` |

## :material-history: Log

| Alias    | Command                        |
| -------- | ------------------------------ |
| `glo`    | `git log --date=rfc`           |
| `gloa`   | `git log --date=rfc --all`     |
| `glog`   | `git log --date=rfc --graph`   |
| `gloga`  | log graph --decorate --all     |
| `glol`   | log graph colored              |
| `glola`  | log graph colored --all        |
| `glon`   | `git log --oneline --decorate` |
| `glona`  | log oneline --all              |
| `glong`  | log oneline --graph            |
| `glonga` | log oneline --graph --all      |
| `glont`  | log oneline --tags             |
| `glop`   | log pretty formatted           |
| `glopa`  | log pretty formatted --all     |
| `glos`   | `git log --date=rfc --stat`    |
| `glosa`  | log stat --all                 |
| `glosp`  | log stat --patch               |
| `glospa` | log stat --patch --all         |

## :material-merge: Merge Tool

| Alias    | Command                     |
| -------- | --------------------------- |
| `gmt`    | `git mergetool --no-prompt` |
| `gmtvim` | mergetool with vimdiff      |

## :material-arrow-down: Pull

| Alias      | Command                       |
| ---------- | ----------------------------- |
| `gpl`      | pull origin + tags + prune    |
| `gpl!`     | pull origin --force           |
| `gpull`    | `git pull`                    |
| `gpullr`   | `git pull --rebase`           |
| `gpullra`  | pull --rebase --autostash     |
| `gpullrav` | pull rebase autostash verbose |
| `gpullrv`  | `git pull --rebase --verbose` |

## :material-arrow-up: Push

| Alias      | Command                       |
| ---------- | ----------------------------- |
| `gpush`    | `git push`                    |
| `gpush!`   | `git push --force-with-lease` |
| `gpushdr`  | `git push --dry-run`          |
| `gpushoat` | push origin --all + --tags    |
| `gpushsup` | push --set-upstream origin    |
| `gpusht`   | `git push --tags`             |
| `gpusht!`  | `git push --tags --force`     |
| `gpushv`   | `git push --verbose`          |

## :material-source-branch-refresh: Rebase

| Alias  | Command                        |
| ------ | ------------------------------ |
| `grb`  | rebase (smart resolve)         |
| `grbo` | fetch + rebase + push if clean |
| `grba` | `git rebase --abort`           |
| `grbc` | `git rebase --continue`        |
| `grbi` | `git rebase --interactive`     |
| `grbs` | `git rebase --skip`            |

!!! info
    `grb` and `grbo` are [helper functions](helpers.md#merge--rebase). `grbo` fetches, rebases,
    and pushes automatically if the rebase is clean.

## :material-undo: Reset

| Alias   | Command                      |
| ------- | ---------------------------- |
| `gr`    | `git reset`                  |
| `grh`   | `git reset --hard`           |
| `grho`  | fetch + reset hard to remote |
| `grho!` | fetch + reset hard + clean   |
| `grs`   | `git reset --soft`           |

!!! danger
    `grh`, `grho`, and `grho!` are destructive - they discard uncommitted changes.

## :material-book-open-page-variant: Reflog / Remove

| Alias   | Command              |
| ------- | -------------------- |
| `grl`   | `git reflog`         |
| `grmc`  | `git rm --cached`    |
| `grm!`  | `git rm --force`     |
| `grmrc` | `git rm -r --cached` |
| `grmr!` | `git rm -r --force`  |

## :material-restore: Restore

| Alias     | Command                  |
| --------- | ------------------------ |
| `grr`     | `git restore`            |
| `grrsrc`  | `git restore --source`   |
| `grrstg`  | `git restore --staged`   |
| `grrstga` | `git restore --staged .` |
| `grp`     | `git rev-parse`          |

## :material-earth: Remote

| Alias     | Command                    |
| --------- | -------------------------- |
| `grt`     | `git remote`               |
| `grta`    | `git remote add`           |
| `grtrm`   | `git remote remove`        |
| `grtrn`   | `git remote rename`        |
| `grtsu`   | `git remote set-url`       |
| `grtup`   | `git remote update`        |
| `grtupp`  | `git remote update --pr.`  |
| `grturl`  | Remote HTTPS URL           |
| `grturlb` | Remote HTTPS URL on branch |
| `grtv`    | `git remote --verbose`     |

!!! tip "Quick repo URL"
    `grturl` prints the remote URL, `grturlb` includes the current branch -
    Ctrl+click to open in the browser.

## :material-information: Show / Status

| Alias  | Command                       |
| ------ | ----------------------------- |
| `gsps` | `git show --pretty=short`     |
| `gst`  | `git status`                  |
| `gstb` | `git status --short --branch` |
| `gsts` | `git status --short`          |

## :material-package-down: Stash

| Alias    | Command             |
| -------- | ------------------- |
| `gsta`   | `git stash push`    |
| `gstaa`  | `git stash push -a` |
| `gstac`  | `git stash clear`   |
| `gstal`  | `git stash list`    |
| `gstap`  | `git stash pop`     |
| `gstaap` | `git stash apply`   |
| `gstad`  | `git stash drop`    |
| `gstas`  | `git stash show`    |
| `gstast` | `git stash show -t` |

## :material-source-branch-plus: Submodule / SVN

| Alias   | Command                |
| ------- | ---------------------- |
| `gsmi`  | `git submodule init`   |
| `gsmu`  | `git submodule update` |
| `gsvnd` | `git svn dcommit`      |
| `gsvnr` | `git svn rebase`       |

## :material-swap-horizontal-bold: Switch

| Alias  | Command                |
| ------ | ---------------------- |
| `gsw`  | switch (smart resolve) |
| `gsw!` | switch --force         |
| `gswc` | `git switch --create`  |
| `gswd` | `git switch --detach`  |
| `gswo` | `git switch --orphan`  |

!!! info
    `gsw` and `gsw!` are [helper functions](helpers.md#switch) that resolve the target branch
    based on branch prefix, falling back to the default branch if nothing is provided.

## :material-tag: Tag

| Alias | Command                   |
| ----- | ------------------------- |
| `gt`  | `git tag --sort=-v:refn.` |
| `gts` | `git tag --sign`          |
| `gtr` | tag list formatted        |

## :material-history: Whatchanged

| Alias  | Command              |
| ------ | -------------------- |
| `gwch` | `git whatchanged -p` |
