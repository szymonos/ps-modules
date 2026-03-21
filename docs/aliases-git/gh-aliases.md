# :octicons-mark-github-16: GitHub CLI Aliases

Aliases for [GitHub CLI](https://cli.github.com/) commands from `Functions/gh.ps1`.

## :octicons-issue-opened-16: Issue

| Alias  | Command         |
| ------ | --------------- |
| `ghil` | `gh issue list` |
| `ghiv` | `gh issue view` |

## :octicons-git-pull-request-16: Pull Request

| Alias     | Command                         |
| --------- | ------------------------------- |
| `ghprc`   | `gh pr create`                  |
| `ghprcf`  | `gh pr create --fill`           |
| `ghprco`  | `gh pr checkout`                |
| `ghprd`   | `gh pr diff`                    |
| `ghprl`   | `gh pr list`                    |
| `ghprm`   | `gh pr merge`                   |
| `ghprmd`  | `gh pr merge --delete-branch`   |
| `ghprr`   | `gh pr ready`                   |
| `ghprs`   | `gh pr status`                  |
| `ghprurl` | `gh pr view --json url --jq ..` |
| `ghprv`   | `gh pr view`                    |
| `ghprck`  | `gh pr checks`                  |

!!! tip "Quick PR URL"
    Use `ghprurl` to grab the current PR's URL for pasting into Slack, Teams, or commit messages.

## :octicons-repo-16: Repository

| Alias   | Command         |
| ------- | --------------- |
| `ghrcl` | `gh repo clone` |
| `ghrfk` | `gh repo fork`  |
| `ghrsy` | `gh repo sync`  |
| `ghrv`  | `gh repo view`  |

## :octicons-play-16: Run (GitHub Actions)

| Alias    | Command        |
| -------- | -------------- |
| `ghrnl`  | `gh run list`  |
| `ghrnv`  | `gh run view`  |
| `ghrnw`  | `gh run watch` |
| `ghrnrr` | `gh run rerun` |

## :material-check-circle: Status

| Alias  | Command     |
| ------ | ----------- |
| `ghst` | `gh status` |
