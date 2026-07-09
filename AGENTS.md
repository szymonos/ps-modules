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
- **Package manager**: `uv` (not pip/poetry). Pre-commit runner: `prek`.
- **Markdown**: ASCII only (the `gremlins-check` hook rejects em dashes, smart quotes, NBSP).
  Tables are auto-aligned by the `align-tables` hook. Config lives in `.markdownlint.yml` -
  do not add alternative config files.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `test:`,
  `refactor:`); scope docs commits (`docs(do-common)`). Never `git add .` / `git add -A`
  during consolidation; force-push only with `--force-with-lease`.
