# :material-format-letter-case: Naming Conventions

Git aliases follow the pattern: **g** + *command* + *modifier* + *action*

GitHub CLI aliases follow the pattern: **gh** + *resource* + *verb*

## :material-source-branch: Git Prefixes

Every git alias starts with `g`, followed by a letter or short abbreviation for the git command.

| Prefix  | Git command    |
| ------- | -------------- |
| `ga`    | `add`          |
| `gb`    | `branch`       |
| `gbl`   | `blame`        |
| `gbs`   | `bisect`       |
| `gc`    | `commit`       |
| `gcf`   | `config`       |
| `gcl`   | `clone`        |
| `gco`   | `checkout`     |
| `gcp`   | `cherry-pick`  |
| `gd`    | `diff`         |
| `gf`    | `fetch`        |
| `gg`    | `grep`         |
| `ghh`   | `help`         |
| `glo`   | `log`          |
| `gmg`   | `merge`        |
| `gmt`   | `mergetool`    |
| `gpl`   | `pull` (smart) |
| `gpull` | `pull`         |
| `gpush` | `push`         |
| `gr`    | `reset`        |
| `grb`   | `rebase`       |
| `grl`   | `reflog`       |
| `grm`   | `rm`           |
| `grr`   | `restore`      |
| `grt`   | `remote`       |
| `gsm`   | `submodule`    |
| `gsps`  | `show`         |
| `gst`   | `status`       |
| `gsta`  | `stash`        |
| `gsw`   | `switch`       |
| `gt`    | `tag`          |
| `gwch`  | `whatchanged`  |

## :material-cog: Common Modifiers

Modifiers are appended to the command prefix to add flags or alter behavior.

| Modifier  | Meaning                        | Example                          |
| --------- | ------------------------------ | -------------------------------- |
| `a`       | `--all`                        | `gba` = `git branch --all`       |
| `!`       | `--force` or `--amend`         | `gpush!` = push --force-w-lease  |
| `o`       | `origin`                       | `gfo` = `git fetch origin`       |
| `p`       | push (appended to commit flow) | `gacp` = add all + commit + push |
| `v`       | `--verbose`                    | `gpushv` = `git push --verbose`  |
| `r`       | `--rebase` or `--remote`       | `gpullr` = `git pull --rebase`   |
| `n`       | `--no-edit`                    | `gcn!` = commit --no-edit amend  |
| `s`       | `--short` or `--signoff`       | `gsts` = `git status --short`    |
| `m`/`msg` | `-m` (message)                 | `gcmsg` = `git commit -m`        |
| `w`       | `--word-diff` or `--watch`     | `gdw` = `git diff --word-diff`   |
| `h`       | `--hard`                       | `grh` = `git reset --hard`       |
| `dr`      | `--dry-run`                    | `gpushdr` = `git push --dry-run` |

## :material-arrow-collapse-right: Commit Combo Aliases

Commit aliases can be composed by combining letters for multi-step operations.

| Pattern                 | Steps                          | Example  |
| ----------------------- | ------------------------------ | -------- |
| `gc` + `m`              | commit -m                      | `gcmsg`  |
| `ga` + `c`              | add all, then commit           | `gac`    |
| `ga` + `c` + `p`        | add all, commit, push          | `gacp`   |
| `gc` + `a`              | commit --all                   | `gca`    |
| `gc` + `a` + `p`        | commit --all, push             | `gcap`   |
| `gc` + `a` + `n!`       | commit --all --no-edit --amend | `gcan!`  |
| `gc` + `a` + `n` + `p!` | above + force push             | `gcanp!` |

!!! tip
    The `p` suffix triggers a push after the commit. When combined with `!` (amend),
    the push uses `--force-with-lease` for safety.

## :octicons-mark-github-16: GitHub CLI Prefixes

GitHub CLI aliases start with `gh`, followed by a resource abbreviation and a verb.

| Prefix | Resource | Prefix | Resource        |
| ------ | -------- | ------ | --------------- |
| `ghi`  | `issue`  | `ghr`  | `repo`          |
| `ghpr` | `pr`     | `ghrn` | `run` (Actions) |
|        |          | `ghst` | `status`        |

**Verb suffixes for resources:**

| Suffix | Verb          | Example                       |
| ------ | ------------- | ----------------------------- |
| `l`    | `list`        | `ghprl` = `gh pr list`        |
| `v`    | `view`        | `ghprv` = `gh pr view`        |
| `c`    | `create`      | `ghprc` = `gh pr create`      |
| `co`   | `checkout`    | `ghprco` = `gh pr checkout`   |
| `m`    | `merge`       | `ghprm` = `gh pr merge`       |
| `md`   | `merge --del` | `ghprmd` = merge --delete-br. |
| `d`    | `diff`        | `ghprd` = `gh pr diff`        |
| `ck`   | `checks`      | `ghprck` = `gh pr checks`     |
| `cl`   | `clone`       | `ghrcl` = `gh repo clone`     |
| `fk`   | `fork`        | `ghrfk` = `gh repo fork`      |
| `sy`   | `sync`        | `ghrsy` = `gh repo sync`      |
| `w`    | `watch`       | `ghrnw` = `gh run watch`      |
| `rr`   | `rerun`       | `ghrnrr` = `gh run rerun`     |
