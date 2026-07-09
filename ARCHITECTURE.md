# Architecture

How this repository is put together: the PowerShell modules, the docs site, and the
Python tooling that lints and publishes them. Read this when you modify module
structure, hooks, the build pipeline, or the docs layout. For day-to-day rules see
[`AGENTS.md`](AGENTS.md); for mistakes made before, see [`design/lessons.md`](design/lessons.md).

## 1. Repository layout

```text
modules/<name>/                PowerShell modules (one subfolder per module)
  <name>.psd1                  manifest (FunctionsToExport, AliasesToExport, RequiredModules)
  <name>.psm1                  root module: dot-sources Functions/*.ps1, then Export-ModuleMember
  Functions/*.ps1              function definitions, grouped by concern
docs/                          MkDocs site source (one subfolder per module + index.md)
  <module>/                    index.md overview, plus subpages for larger modules
src/hooks/                     custom pre-commit hook scripts (Python)
design/lessons.md              operational lessons compounded by /prepare-pr
.claude/skills/                agent skills (Claude Code slash commands)
module_manage.ps1              install / remove / scaffold modules
Makefile                       primary entry point (make = help)
pyproject.toml + uv.lock       Python deps (mkdocs, ruff, prek) managed by uv
mkdocs.yml                     MkDocs Material config
.pre-commit-config.yaml        hook definitions (run via prek)
```

## 2. Module system

Each module under `modules/<name>/` has three moving parts that must stay in sync:

- **`<name>.psd1`** - the manifest. `FunctionsToExport` and `AliasesToExport` list the
  public surface; `RequiredModules` / `#Requires` declare dependencies.
- **`<name>.psm1`** - the root module. It dot-sources every `Functions/*.ps1` file at the
  top, then calls `Export-ModuleMember` with an explicit `Function` + `Alias` list (never a
  `*` wildcard - the explicit list keeps the public surface auditable and matched to the
  manifest).
- **`Functions/*.ps1`** - the actual function definitions, grouped by concern (e.g.
  `certs.ps1`, `net.ps1`, `python.ps1`).

### Module inventory

| Module            | Function files | Purpose                                                            |
| ----------------- | -------------- | ------------------------------------------------------------------ |
| `aliases-git`     | 6              | 200+ `git`/`gh` alias functions built on `Invoke-WriteExecCommand` |
| `aliases-kubectl` | 6              | 790+ composable `kubectl` aliases from a strict naming pattern     |
| `do-az`           | 4              | Azure: subscriptions, Key Vault, AKS, Resource Graph, MS Graph     |
| `do-common`       | 7              | Cross-platform, dependency-free: encoding, certs, venvs, net       |
| `do-linux`        | 2              | Linux/WSL system info and sudo wrappers                            |
| `do-win`          | 3              | Windows utilities (Linux-like commands, PATH, winget)              |
| `psm-windows`     | 1              | Windows PowerShell (5.1) helpers                                   |

### The three-file sync invariant

Adding, renaming, or removing a public function or alias must touch all three places or the
module ships broken:

1. the function body in `Functions/<file>.ps1`,
2. the export list in `<name>.psm1` (plus a `. $PSScriptRoot/Functions/<file>.ps1`
   dot-source line if the file is new),
3. `FunctionsToExport` / `AliasesToExport` in `<name>.psd1`.

A symptom of a broken invariant: an export listed in the manifest/psm1 but not defined (or
vice versa), a new `Functions/*.ps1` never dot-sourced, or a `Set-Alias` whose alias is
missing from the export lists. Each module's public surface is also documented under
`docs/<module>/`; changing exports usually needs a matching docs edit.

### Alias-function pattern

The alias modules (`aliases-git`, `aliases-kubectl`) build every alias on
`Invoke-WriteExecCommand` (defined in `Functions/internal.ps1`), which prints the command in
magenta then executes it via `Invoke-Expression`. All aliases support `-WhatIf` (preview)
and `-Quiet` (silent) parameter sets.

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

Omit the `$Xargs` param only when the command takes no extra arguments (e.g.
`git restore --staged .`).

### Managing modules

`module_manage.ps1` installs, removes, and scaffolds modules; the Makefile wraps common
invocations (`make install-common-do`, `make install-git-aliases`, etc.). Elevated sessions
install to the AllUsers scope automatically. Requires PowerShell 7+.

## 3. Pre-commit hooks

`make lint` runs the hooks via `prek` (a `pre-commit` wrapper), configured in
`.pre-commit-config.yaml`. Do not run the underlying tools individually.

### Custom hooks (3 Python scripts in `src/hooks/`)

| Hook                  | What it does                                                                    |
| --------------------- | ------------------------------------------------------------------------------- |
| `gremlins-check`      | Fails on unwanted Unicode (em dashes, smart quotes, NBSP, zero-width, etc.)     |
| `align-tables`        | Auto-aligns markdown table columns so every row's pipes share a column (MD060)  |
| `validate-docs-words` | Prunes unused words from `project-words.txt`, writes back sorted + deduplicated |

### Vendored hooks

`mkdocs-build` (`mkdocs build --strict`), `ruff-check`, `ruff-format` (both scoped to
`src/`+`tests/`), `check-executables-have-shebangs`, `check-shebang-scripts-are-executable`,
`end-of-file-fixer`, `mixed-line-ending`, `trailing-whitespace`, `markdownlint-cli2` (all
`.md`), and `cspell` (docs + commit messages).

## 4. Build and docs pipeline

- **Docs**: MkDocs with the Material theme. Config in `mkdocs.yml`, deps in `pyproject.toml`.
- **Preview**: `make mkdocs-serve` (live reload). **Build**: `make mkdocs-build`
  (`--strict`; strict-mode warnings fail the build).
- **Deploy**: `.github/workflows/gh-pages.yml` runs `mkdocs gh-deploy`; `make mkdocs-pages`
  does it locally.
- **CI**: `.github/workflows/repo_checks.yml` runs the prek hooks against the PR diff on
  every pull request.
- Doc filenames use hyphens (`aliases-git/`, not `aliases_git/`). Each module gets its own
  folder under `docs/`; small modules use a single `index.md`, larger ones split into pages
  by function group.

### MkDocs / Markdown conventions

- **Emojis** in titles: `:material-git:`, `:octicons-mark-github-16:`, etc.
- **Admonitions**: `!!! note`, `!!! tip`, `!!! warning`, `!!! danger`, `!!! example`, `!!! info`.
- **Collapsible blocks**: `??? info "Title"` (content indented 4 spaces).
- Tables inside admonitions/collapsible blocks need a blank line after the opener and
  4-space indentation.
- **`.markdownlint.yml`**: MD013 line length 120 (code blocks + tables exempt), MD024
  siblings_only, MD046 disabled. Do not create alternative markdownlint config files - edit
  `.markdownlint.yml` only.
- Custom spelling words go in `project-words.txt` (lowercase, sorted); the
  `validate-docs-words` hook removes unused entries automatically.

## 5. Tooling and workflow

- **Package manager**: `uv` (not pip/poetry) - deps in `pyproject.toml`, lockfile `uv.lock`.
- **Python version**: `~=3.14.0`.
- **Pre-commit runner**: `prek`, invoked via `uv run --frozen prek`. All `lint*` targets
  accept `HOOK=<id>` to run a single hook (e.g. `make lint HOOK=gremlins-check`).
- **Conventional Commits** for messages (`feat:`, `fix:`, `docs:`, `chore:`, `test:`,
  `refactor:`). Scope module docs commits: `docs(do-common)`, `chore(hooks)`.
- During branch consolidation: never `git add .` / `git add -A` (use explicit file lists),
  and force-push only with `--force-with-lease`.

## 6. Agent skills

Skills live in `.claude/skills/` as Claude Code slash commands.

| Skill               | Purpose                                                               |
| ------------------- | --------------------------------------------------------------------- |
| `second-opinion`    | Heterogeneous-model review via GitHub Copilot CLI (GPT)               |
| `address-pr-review` | Drive server-side Copilot PR review to a clean state                  |
| `prepare-pr`        | Consolidate WIP commits by prefix, lint, push, and create/update a PR |
