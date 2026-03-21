# AGENTS.md

## Tooling

- **Primary interface**: `make` (Makefile) - run `make` to see available targets
- **Package manager**: `uv` (not pip/poetry) - see <https://docs.astral.sh/uv/llms.txt>
- **Linting**: `make lint` runs pre-commit hooks via `prek` (not pre-commit).
  Hooks are configured in `.pre-commit-config.yaml` and include: `ruff` (Python),
  `markdownlint-cli2` (Markdown), `cspell` (spelling), `mkdocs build --strict`,
  gremlins check, and docs word validation. Do not run these tools individually.
- **Docs**: `mkdocs` with Material theme (`make mkdocs-serve` to preview)

## IMPORTANT: Always Validate Changes

After every code or documentation change, run `make lint` and fix all failures before proceeding.
Do not skip this step. Do not assume changes are correct without running lint.

## Project Structure

```text
modules/<name>/
  <name>.psd1          # manifest (FunctionsToExport, AliasesToExport)
  <name>.psm1          # root module (dot-sources, Export-ModuleMember)
  Functions/*.ps1      # function files
docs/
  <module>/            # each module has its own folder
    index.md           # module overview
    *.md               # subpages (aliases, helpers, completers, etc.)
src/
  align_tables.py      # markdown table alignment script
  hooks/               # pre-commit hook scripts
pyproject.toml         # Python deps (mkdocs, etc.) managed by uv
```

## Adding a New Alias Function

Three files must be updated in sync:

1. **`Functions/<file>.ps1`** - add the function
2. **`<module>.psm1`** - add to export list + dot-source if new file
3. **`<module>.psd1`** - add to `FunctionsToExport`

### Alias Function Pattern

All alias functions use `Invoke-WriteExecCommand` (defined in `Functions/internal.ps1`).
It prints the command in magenta then executes it via `Invoke-Expression`.

```powershell
function gexample {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git example' @PSBoundParameters
}
```

Omit `$Xargs` param only when the command takes no extra arguments (e.g. `git restore --staged .`).

## Markdown Rules

### Gremlins

Pre-commit rejects Unicode characters like em dashes (U+2014), smart quotes, etc. Use plain ASCII only.

### Table Alignment (MD060)

The linter enforces **aligned** table style - every row's pipe characters must be at the exact same column
as the header. Use the alignment script after editing tables:

```bash
python3 src/align_tables.py docs/**/*.md
```

### Spelling

Custom words go in `project-words.txt` (lowercase, sorted). The `validate-docs-words` pre-commit
hook removes unused words automatically. Do NOT create alternative markdownlint config files -
modify `.markdownlint.yml` only.

### Markdownlint Config

`.markdownlint.yml` settings:

- MD013: line length 120, code blocks and tables exempt
- MD024: siblings_only
- MD046: disabled

## mkdocs

- Config: `mkdocs.yml`, deps in `pyproject.toml` (managed by `uv`)
- Deploy: `.github/workflows/gh-pages.yml` uses `uv run mkdocs gh-deploy --force`
- Doc filenames use hyphens (`aliases-git/` not `aliases_git/`)
- Each module gets its own folder under `docs/`; small modules use a single `index.md`,
  larger modules split into multiple pages by function group

### mkdocs Features

Docs use Material for MkDocs with these extensions:

- **Emojis** in titles: `:material-git:`, `:octicons-mark-github-16:`, etc.
- **Admonitions**: `!!! note`, `!!! tip`, `!!! warning`, `!!! danger`, `!!! example`, `!!! info`
- **Collapsible blocks**: `??? info "Title"` (content must be indented 4 spaces)
- Tables inside admonitions/collapsible blocks need blank line after the opener and 4-space indentation
