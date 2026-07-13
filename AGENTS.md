# ps-modules

Cross-platform PowerShell modules, plus the MkDocs site and Python tooling that document and
lint them.

## Compound knowledge

Two knowledge layers beyond this file. Read on demand, not upfront:

| Layer                                    | When to read                                               | What it answers        |
| ---------------------------------------- | ---------------------------------------------------------- | ---------------------- |
| [`ARCHITECTURE.md`](ARCHITECTURE.md)     | Modifying module structure, hooks, skills, build pipeline  | How things connect     |
| [`design/lessons.md`](design/lessons.md) | Fixing bugs, repeating a mistake, touching hooks or skills | What went wrong before |

Skip both for content-only edits to existing docs, typo fixes, and conversational questions.

> **Module changes are versioned.** Any edit under `modules/<name>/` must bump
> `ModuleVersion` in `<name>.psd1` in the **same, module-only** commit, with
> message `<prefix>: <name> vX.Y.Z` (e.g. `feat: do-common v1.9.0`,
> `refactor: aliases-git v1.23.1`). Files that only *use* the module do not
> trigger a bump. See [`ARCHITECTURE.md`](ARCHITECTURE.md) §2c for the SemVer
> rule and the "bump only against released code" gotcha.

## Common commands

**IMPORTANT**: Always run `make lint` after every code or docs change and fix all failures
before reporting done. Do not run the underlying tools individually.

```bash
make                  # list available targets
make lint             # run pre-commit hooks on changed files (run after every change)
make lint-diff        # run hooks on files changed since main (use after /prepare-pr Phase 2)
make lint-all         # run hooks on the entire repo
make lint HOOK=<id>   # run a single hook by ID (e.g. make lint HOOK=gremlins-check)
make mkdocs-build     # build the site with --strict; zero warnings required for docs changes
make mkdocs-serve     # preview the site locally with live reload
```

## Golden rules

- **Modules**: adding/renaming/removing a public function or alias must update all three of
  `Functions/<file>.ps1`, `<module>.psm1` (export list + dot-source), and `<module>.psd1`
  (`FunctionsToExport`/`AliasesToExport`). See ARCHITECTURE.md section 2.
- **Module versioning**: every edit under `modules/<name>/` bumps `ModuleVersion` in
  `<name>.psd1` in the same module-only commit, using `<prefix>: <name> vX.Y.Z`. See
  ARCHITECTURE.md §2c.
- **Package manager**: `uv` (not pip/poetry). Pre-commit runner: `prek`.
- **Markdown**: mostly ASCII (the `gremlins-check` hook auto-fixes smart quotes and most invisibles;
  it allows EM DASH, NBSP, HORIZONTAL ELLIPSIS, and MIDDLE DOT in `.md`/`.html`/`.htm` since those
  serve legitimate typographic purposes). Plain code and prose outside markup are ASCII-only.
  Tables are auto-aligned by the `align-tables` hook. Config lives in `.markdownlint.yml` -
  do not add alternative config files.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `test:`,
  `refactor:`); scope docs commits (`docs(do-common)`). Never `git add .` / `git add -A`
  during consolidation; force-push only with `--force-with-lease`.
