# Operational Lessons

Generalized rules extracted from PR history by `/prepare-pr`. Each entry captures a pattern the agent learned the
hard way and the rule that prevents recurrence. Reviewed in the PR diff before merge.

---

## L-001 - 2026-07-09 - uri-parsing

**Source:** PR #268, branch `fix/certificate-port-error-handling`

When hand-rolling a URI/authority parser instead of using `[System.Uri]`, split the authority on the full set of
delimiters `[/?#]`, not just `/`. A query string or fragment that follows the host with no intervening slash (e.g.
`https://host:8443?q=1`) otherwise stays glued to the port and corrupts host/port extraction. Prefer `[System.Uri]`
for absolute URIs and reserve manual parsing for bare `host` / `host:port` inputs; if manual parsing is kept, make
the code strip every component the docstring claims it strips.

---

## L-002 - 2026-07-13 - directory-move-artifact-audit

**Source:** PR #269, branch `rfr/agentic`

When relocating a directory (e.g. `hooks/` → `hooks/`), the file move is only half the change. Every place
that named the *old* location as a string - regex scopes in `.pre-commit-config.yaml` (`files: ^(src|tests)/`),
path-prefix maps in config TOML (`[architecture_sections]` in `.claude/prepare-pr.toml`), Python module dotted
paths in hook entries (`python3 -m src.hooks.foo`), documentation snippets showing repo layout - has to move
too, or coverage silently disappears. `git mv` only refactors the tracked files; it doesn't touch string
references to the old path elsewhere in the tree. Before committing a move, `git grep '<old-prefix>'` across
config, docs, and scripts and reconcile every hit; treat any survivor as a bug the CI won't catch (because the
tools it configures just silently match nothing).

---

## L-003 - 2026-07-13 - hook-policy-doc-sync

**Source:** PR #269, branch `rfr/agentic`

When a lint or pre-commit hook relaxes or tightens its policy (e.g. `gremlins.py` allowing EM DASH / NBSP /
ellipsis / middle dot in `.md`/`.html`/`.htm` files), update the *human-facing* description of that policy in
the same commit. The hook's own docstring is not enough - contributor-facing docs (`AGENTS.md`,
`REVIEW-BRIEF.md`, `ARCHITECTURE.md`) and code-review guidance are what agents and reviewers actually read, so
stale claims like "ASCII-only" cause needless rework and misdirected review findings. Pattern: before landing
a hook-behavior change, `git grep -l '<policy-summary-keyword>'` (e.g. "ASCII only", "rejects em dashes")
across the repo and reconcile each hit.

---

## L-004 - 2026-07-17 - module-api-rename-doc-sync

**Source:** PR #270, branch `fix/do-common`

When renaming or removing a public parameter (or any exported surface) of a versioned module, `git grep` the
old name across `docs/`, `README.md`, and example snippets in the same change and reconcile every hit -
`FunctionsToExport`/`AliasesToExport` and the manifest bump only track the *code* surface, so published usage
examples silently drift and ship copy-pasteable commands that fail against the new API. Pattern: before
finalizing a `-OldParam` -> `-NewParam` rename, `git grep -n 'OldParam'` and fix docs, then let the
heterogeneous reviewer confirm (this lesson exists because `/second-opinion` caught exactly this drift after
the code review missed it).
