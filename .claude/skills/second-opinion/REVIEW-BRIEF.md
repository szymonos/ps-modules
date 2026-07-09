---
repo: szymonos/ps-modules
---

# Review brief

Curated context for a heterogeneous-model reviewer (`/second-opinion`).
You are reviewing a code diff. Read this brief first, then the diff, then any files needed for context.

## Project

A collection of cross-platform PowerShell modules, plus the tooling that packages and documents them. Four concerns
in one repo:

1. **PowerShell modules** (`modules/<name>/`) - the primary content. Seven modules:
   `aliases-git`, `aliases-kubectl` (composable `git`/`gh` and `kubectl` alias functions),
   `do-az` (Azure: subscriptions, Key Vault, AKS, Resource Graph, MS Graph),
   `do-common` (cross-platform, dependency-free: encoding, certs, Python venvs, shell helpers, networking),
   `do-linux`, `do-win` (OS-specific utilities), `psm-windows`.
2. **Python pre-commit hooks** (`src/hooks/`) - `align_tables.py`, `gremlins.py`, `validate_docs_words.py`.
3. **Agent skills** (`.claude/skills/`) - Claude Code slash commands with bundled Python/bash helper scripts.
4. **Docs** (`docs/`) - one folder per module, published as a static site via `mkdocs-material`
   (`mkdocs build --strict`).

Tooling: `make` is the entry point, `uv` manages Python deps, `prek` runs the pre-commit hooks. Modules are
installed/scaffolded via `module_manage.ps1`. Requires PowerShell 7+.

## Module layout and invariants

Each module is `modules/<name>/` with:

- `<name>.psd1` - manifest; `FunctionsToExport` and `AliasesToExport` lists.
- `<name>.psm1` - root module; dot-sources every `Functions/*.ps1`, then `Export-ModuleMember` with an
  explicit `Function` + `Alias` list.
- `Functions/*.ps1` - the actual function definitions.

**Three-file sync invariant (highest-value thing to check).** Adding, renaming, or removing a public function
or alias must be reflected in all three places, or the module ships broken:

1. the function body in `Functions/<file>.ps1`,
2. the export list in `<name>.psm1` (plus a `. $PSScriptRoot/Functions/<file>.ps1` dot-source line if the file is new),
3. `FunctionsToExport` / `AliasesToExport` in `<name>.psd1`.

A function present in a psd1/psm1 export list but not defined (or vice versa), a new `Functions/*.ps1` file that
`<name>.psm1` never dot-sources, or a `Set-Alias` whose alias is missing from the export lists - all are real bugs.

**Docs correspondence.** Each module's public surface is documented under `docs/<module>/`. A new/renamed/removed
public function usually needs a matching docs edit; a diff that changes exports but not docs is worth a `warning`.

## Focus areas (ordered by importance)

1. **PowerShell correctness** - logic errors in module functions. Watch for: pipeline `begin`/`process`/`end`
   misuse (per-item work in `begin`), unhandled `$null`, missing `[CmdletBinding()]`/`param` blocks, wrong
   `ParameterSetName` wiring, `$PSBoundParameters` splatting that forwards params the callee doesn't accept,
   undisposed `IDisposable` objects (streams, TCP clients), swallowed errors, and `Throw`/`Write-Error` where a
   terminating `$PSCmdlet.ThrowTerminatingError(...)` would give a cleaner call site. Verify string interpolation,
   regex, and `-match`/`-replace` patterns.
2. **Export / manifest integrity** - the three-file sync invariant above. Also `#Requires` statements and
   `RequiredModules` in manifests that don't match actual usage.
3. **Alias-function pattern** - alias modules (`aliases-git`, `aliases-kubectl`) build on `Invoke-WriteExecCommand`
   (see `Functions/internal.ps1`), which prints the command then runs it. Check that `-WhatIf`/`-Quiet` parameter
   sets are wired correctly and `[Parameter(ValueFromRemainingArguments)]$Xargs` is present unless the command
   takes no extra args.
4. **Python correctness** - logic errors in `src/hooks/` and `.claude/skills/*/scripts/`. Type safety, edge cases,
   unchecked returns, subprocess error handling, regex bugs, unintended file mutation.
5. **Skill design** - `SKILL.md` instructions that contradict each other, reference non-existent files/commands,
   use wrong phase numbers, or create circular skill dependencies.
6. **Docs & Markdown** - broken tables (mismatched columns), unclosed fenced code blocks, heading hierarchy
   violations, and content that breaks `mkdocs build --strict` (bad relative links, missing nav targets).

## Known patterns - do NOT flag

These are deliberate. Flagging them is noise:

- **`prek` instead of `pre-commit`** - `prek` is the pre-commit runner used in this project (via `make lint`).
- **ASCII-only punctuation (hyphens, not em/en dashes; straight quotes)** - enforced by `src/hooks/gremlins.py`,
  which rejects em dashes, smart quotes, non-breaking spaces, etc. Plain `-` in prose is correct, not a typo.
- **`validate_docs_words.py` rewriting `project-words.txt`** - the hook intentionally prunes unused words and
  writes back a sorted, lowercased, deduplicated list. Mutating that file is the hook's job, not a bug.
- **Aligned Markdown tables** - the `align-tables` hook (MD060) auto-formats tables so every row's pipes share a
  column. Pre-existing alignment is machine-generated; don't flag column padding as a style issue.
- **`disable-model-invocation` in skill frontmatter** - controls whether a skill can be invoked programmatically
  by other skills. Intentional per-skill setting, not stale metadata.
- **`--no-custom-instructions` / `--allow-all-tools` in the second-opinion skill** - deliberate; see its SKILL.md
  rationale (process-boundary bias control).
- **`ubuntu-slim` as a GitHub Actions runner** - valid GitHub-hosted runner, used intentionally.
- **`REVIEW-BRIEF.md` with `repo:` frontmatter tag** - portability mechanism; not stale metadata.
- **Explicit per-module `Export-ModuleMember` lists** (rather than `Functions/*` wildcards) - intentional; keeps
  the public surface auditable and matches `FunctionsToExport` in the manifest.
- **`Invoke-Expression` inside `Invoke-WriteExecCommand`** - intentional design of the alias modules (the command
  string is printed then executed); not an injection oversight in this context.

## Output format

Produce a single markdown response with this structure:

```text
## Findings

### F-001 - <severity> - <file>:<line>
<one-paragraph description; reference the constraint being violated; be specific>

**Suggestion:** <concrete fix direction, NOT a patch>

### F-002 - <severity> - <file>:<line>
...
```

Severities:

- **`bug`** - correctness or security defect; the code is wrong.
- **`warning`** - likely issue, needs judgment; the code might be wrong under conditions you can't fully verify.
- **`nit`** - style or clarity; the code works but could be clearer.

If zero findings, output exactly: `No findings.`

## Bias-control rules

- Speculate carefully. If you suspect a bug but can't verify the call site, mark `warning` not `bug`.
- Don't pad with `nit` findings to look productive. Five `nit` items on a 200-line diff is fine; thirty is noise.
- If several findings share the same root cause, consolidate into one finding with multiple `<file>:<line>` references.
