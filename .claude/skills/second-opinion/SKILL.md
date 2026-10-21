---
name: second-opinion
argument-hint: "[COMMIT] [model ID]"
description: Heterogeneous-model code review of the current branch's changes. Invokes GitHub Copilot CLI with gpt-6-luna (gpt-6-sol for security-sensitive or very large diffs) to review git diff since merge-base with the repo's trunk branch (or user-specified commit). Reads .claude/skills/second-opinion/REVIEW-BRIEF.md for focused project context. Returns structured findings that Claude reads, summarizes, and acts on. Use when the user types `/second-opinion`, asks for a second opinion on a branch, wants GPT to review the work, or wants an independent review before pushing.
disable-model-invocation: false
---

# Second opinion

<!-- skillkit: no-command summarize (the agent summarises the findings) -->

Heterogeneous-model author-time review of the current branch. Runs **GitHub Copilot CLI** (`copilot`) with a GPT-family model (`gpt-6-luna`, or `gpt-6-sol` for a sensitive or large diff - see Model override) against the diff since the merge-base with the repo's default branch, resolved in Phase 1. The reviewer returns structured findings; Claude reads them and acts.

The bias-control mechanism is **the process boundary itself**. Copilot runs as a separate binary, with a separate model family, returning only text. Claude (the implementer) cannot influence Copilot's review, and Claude acts only on the findings Copilot returns. Each pass also runs in its own throwaway clone, so a pass cannot touch your checkout either.

## When to use

- `/second-opinion` - review the current branch against its merge-base with the trunk (autodetected in Phase 1)
- `/second-opinion <commit>` - review since an arbitrary commit hash
- `/second-opinion model <id>` - use a different Copilot model, such as `gpt-6-sol`
- "Get a second opinion before I push" / "have GPT review this" - same as `/second-opinion`

## Prerequisites

`copilot` CLI installed and authenticated. `run` looks on `PATH`, then for the copy VS Code Server installs outside it, and exits 4 only when neither exists. Only then tell the user to install via `https://gh.io/copilot-install` and run `copilot login`. Updates via `copilot update`.

## Workflow

### Phase 0 - verify review brief

Run the bundled check script to verify `REVIEW-BRIEF.md` targets this repo:

```bash
scripts/review_brief.py check
```

Returns JSON with `match`, `brief_repo`, `current_repo`, `needs_update`, `premium_triggers`, `brief_path` and `write_to`. `brief_path` is the brief `run` hands Copilot in Phase 1: the repo's own when it has one, else the one bundled with the skill. **Write a rewritten brief to `write_to`**, the repo's own path - never to `brief_path` when it is the bundled copy, which every other repo shares. `write_to` is `null` when a link on the way to it - `.claude/skills`, the skill directory or the brief itself - leads out of the repo; then there is no safe place to write, so use the existing brief and tell the user.

- **Match**, or `needs_update: false` because `gh` could not name the repo -> proceed to Phase 1. When `premium_triggers` is 0, the brief predates model escalation, so only a diff over 1200 code lines can pick `gpt-6-sol`. First offer, via `AskUserQuestion`, to add a "Premium review triggers" section (see the bullet below) to `write_to`, with globs drawn from the repo's security-sensitive paths.
- **Mismatch or missing `repo:` tag** -> run discovery and offer a one-time rewrite:

  ```bash
  scripts/review_brief.py discover
  ```

  The discovery output includes detected stacks, context from `CLAUDE.md`/`AGENTS.md`/`README.md`, and the existing brief content. Use this context to rewrite `REVIEW-BRIEF.md` with:
  - Updated `repo:` frontmatter tag matching the current repo
  - Project description derived from the discovered context
  - Focus areas appropriate for the detected tech stack
  - A "Premium review triggers" section: one ``- `glob` `` bullet per security-sensitive path (code run as root, TLS trust, credentials, anything that deletes user files or writes shared state)
  - Empty "Known patterns - do NOT flag" section (compounding loop will fill it)
  - Same output format and bias-control rules (these are repo-agnostic)

  Present the rewrite to the user via `AskUserQuestion` ("Update REVIEW-BRIEF.md for this repo?"). On approval, write it to `write_to`. On decline, proceed with the existing brief (it may produce noisy or irrelevant findings).

This phase runs once per repo. After the brief is updated, `check` returns `match: true` on all subsequent runs.

### Phase 1 - run the review

This skill is portable across repos that use `main`, `master`, `trunk`, `prod`, etc. - never assume `main`. One command resolves the base, runs three Copilot passes in parallel and merges their findings:

```bash
scripts/review_brief.py run                          # since the merge-base with the trunk
scripts/review_brief.py run <commit>                 # the caller passed an explicit base
scripts/review_brief.py run --model gpt-6-sol        # see Model override
scripts/review_brief.py run v1.4.0 --intent notes.md --files src/a.py src/b.py --timeout 540
```

- **`--intent FILE-OR-TEXT`** - the author's stated intent, such as a CHANGELOG section. A path that exists is read as a file. Every pass gets it as context for telling deliberate behaviour from accidental, never as a list of findings to suppress.
- **`--files PATH ...`** - review only these paths, for a rerun scoped to what changed since the last review.
- **`--timeout SECONDS`** - the limit for each pass, default 1200. Passes run at once, so the whole run takes about that long at worst. Set it below any timeout the caller itself runs under.

The passes are lenses on the same diff. **`logic`** hunts defects inside the changed lines. **`inputs`** feeds the changed code wrong types, empty, zero, negative and aliased paths, and checks for tracebacks, false "clean" results, wrong exit codes and non-atomic writes. **`impact`** hunts what the change breaks outside the diff: callers and tests of a changed signature, docs, SKILL.md files and tables that now disagree with the code, missing timeouts. One general pass reliably finds the first kind and rarely the other two, which a server-side PR review then catches one push at a time. Each lens costs one model call and they run concurrently, so wall time is one review.

It prints JSON: the base (`trunk`, `trunk_ref`, `base`, `head`, `commits`, `diffstat`), then `uncommitted`, `model` (with `model_reasons` and `code_lines` when `run` chose it), `brief`, `raw` - `{lens: temp file}` holding each pass's full output - and `findings`: `[{id, severity, file, line, description, suggestion, lens}, ...]` with `count`. Lenses overlap, so the list can name one defect twice. **Consolidate findings that share a root cause** before presenting them, and keep apart those that merely sit near each other. The trunk comes from `origin/HEAD`, then GitHub's default branch, then `main`/`master`/`trunk`/`prod`, and resolves to a local branch or, in a CI checkout that only has the remote, to `origin/<name>`.

- **Exit 3** - nothing past the base, committed or not, or nothing under `--files` (`reason` says so). Copilot was not called. Stop: "Nothing to review - branch is at parity with the base."
- **Exit 4** - no Copilot CLI anywhere. Copilot was not called, and `skipped` carries the install hint. Tell the user; a caller such as a release driver can treat it as a skipped layer rather than a failure.
- **Exit 1** - `error` says what stopped the review (base unresolvable, no brief, every pass failed or hung) and the fix; `stderr` carries Copilot's own message. Surface it; don't retry automatically.
- **Exit 0** - if `failed` is present, one lens did not finish: say which, and that its half of the review is missing. If `unparsed` is present, `{lens: [heading, ...]}` names finding headings that broke the brief's format: read that pass's `raw` file for them rather than dropping them. If `count` is 0, announce "No findings." and exit. Otherwise act on `findings` below.

`scripts/review_brief.py base [<commit>]` prints the base part alone, for callers that only need it. `scripts/review_brief.py parse <file>` re-parses one pass's saved output, such as `raw["impact"]`.

**Uncommitted work is reviewed too, with no WIP commit.** When the tree is dirty, `run` snapshots it - staged, unstaged and untracked files, honouring `.gitignore` - into a commit object built through a scratch index. No branch, index or file moves, so there is nothing to undo. `head` is then that snapshot, `uncommitted` is `true`, and Copilot diffs `<base>..<head>` while reading the same files from the working tree. `commits` still counts only real commits.

#### The Copilot call `run` makes

Each pass's prompt tells Copilot to read the brief, run `git diff <base>..<head>` itself, apply its lens, re-read the code behind each finding and drop what it cannot confirm, then answer in the brief's format. All use these flags:

- **`-s`** (silent) - strips UI chrome, leaves only the agent's response on stdout. Critical for parsing.
- **`--no-custom-instructions`** - skips `AGENTS.md` auto-loading. The curated `REVIEW-BRIEF.md` is the only context Copilot needs. Loading everything would burn attention budget on irrelevant context.
- **`--excluded-tools skill`** - `--no-custom-instructions` does not hide `.claude/skills/`. Without this flag a pass can invoke this very skill, which starts a nested review on whatever model that copy defaults to: three passes replaying an old commit each launched one on `gpt-5.3-codex`, at 20-27 AI Credits apiece against 2-3 for the pass itself.
- **`--allow-all-tools`** - required for non-interactive `-p` mode, and not a sandbox: a pass can write, delete and run code. That is why each pass runs in its own throwaway clone (`git clone --shared`, no `origin` remote), checked out at the reviewed `head`, with its copy of the brief kept beside the clone rather than in it. A clone rather than a linked worktree, because a worktree shares refs, the stash and config with your checkout. Nothing a pass does - files, `git tag`, `git stash`, config - reaches your checkout or races another pass. The clone holds only tracked and snapshotted files, so gitignored local state such as `.venv` is absent there. **The clone isolates files and git state, not credentials or network**: a pass inherits your environment and can read credential files in your home directory. The `inputs` lens is told to run code only when it stays inside its clone, with no network, credentials or live-write flags, and to reason from the source otherwise. That is an instruction to the reviewer, not a boundary, and no generic one exists: credentials live in files as often as in variables, and Copilot itself needs the network.
- **`--model`** - the model `run` chose, or the one passed with `--model`. See Model override.

### Phase 2 - act on findings

#### Output handling

Two modes, selected by the caller via context (the skill itself doesn't need to know who called it):

**Interactive mode** (default - standalone `/second-opinion`):

1. Present a summary table to the user:

   ```text
   ## Copilot review (gpt-6-luna) - 3 findings

   | ID | Severity | Lens | Location | Summary |
   |----|----------|------|----------|---------|
   | F-001 | bug | logic | src/main.py:142 | <one-line> |
   | F-002 | warning | inputs | lib/utils.sh:88 | <one-line> |
   | F-003 | nit | impact | docs/index.md:23 | <one-line> |
   ```

2. Ask via `AskUserQuestion` which to act on. For 4 or fewer findings, use one question with multiSelect options (`F-001`, `F-002`, ...). For more, present in chunks of 4 or ask "fix all bugs, triage warnings/nits?" first.
3. For each finding the user wants fixed: Claude reads the relevant file, formulates a fix from Copilot's `Suggestion`, applies it via `Edit`. **Do not copy Copilot's patch verbatim** - Copilot suggests direction; Claude writes the actual edit using its own knowledge of the codebase.
4. After edits, run `make lint` to validate.

**Automated mode** (when invoked by another skill as a pre-push review gate):

1. Auto-fix findings with `severity: bug` AND a concrete `Suggestion` that maps cleanly to one or two lines of code. No user prompt needed for these - they're obvious corrections.
2. Surface to the user via `AskUserQuestion`:
   - Any `bug` finding where the fix is non-obvious or spans multiple files.
   - All `warning` findings (by definition, judgment is needed).
   - `nit` findings only if the user explicitly opted in (default: skip nits - they're not blockers).
3. After resolution, re-run `make lint` to validate.
4. Return control to the caller. Review-driven fixes are uncommitted working-tree changes - the caller decides how to commit them.

The caller selects automated mode by passing findings context (e.g., "act on findings per automated mode"). Without that context, the skill defaults to interactive mode.

## Model override

Without `--model`, `run` picks one of two models and says why in `model_reasons`. State the choice in one line before presenting findings ("Reviewed with gpt-6-sol: touches trigger paths: ...").

| Model ID     | Tier     | When                                                                                                                   |
| ------------ | -------- | ---------------------------------------------------------------------------------------------------------------------- |
| `gpt-6-luna` | standard | **Default** - 1.2-2.5 AI Credits per pass, 5-6 per three-pass review                                                   |
| `gpt-6-sol`  | premium  | ~20x luna. Picked when the diff touches a "Premium review triggers" glob in the brief, or changes over 1200 code lines |

The user types `/second-opinion model <id>` to choose instead. Pass it on as `scripts/review_brief.py run --model <id>`.
Any other model Copilot offers is accepted on request (list them with `copilot -p "list available models"`). Avoid Claude models: they share a family with the implementer, which defeats the point of a heterogeneous review.

Credit figures are measured on 200- to 1,100-line diffs; one AI Credit is $0.006. `-s` hides the usage line - read `totalNanoAiu` (10^9 per credit) from the `session.shutdown` event in `~/.copilot/session-state/<id>/events.jsonl`.

On a planted-bug comparison (2026-09-24) luna and sol found the same bugs with no false positives; sol added one minor documentation finding across two runs. Neither caught a bug that needed outside knowledge, so a stronger reviewer does not replace the challenge step.

## Anti-patterns

- **Running `/second-opinion` repeatedly on the same diff.** Wastes Copilot API tokens. If the first run missed something, evolve `REVIEW-BRIEF.md` (add a focus area), don't re-run.
- **Treating a clean run as a substitute for the PR review.** The `inputs` and `impact` lenses move those checks earlier, but a server-side review still sees the PR as merged. Run it once at the end; a finding it makes that this skill missed belongs in the brief.
- **Dropping `--no-custom-instructions`.** Copilot would auto-load `AGENTS.md` - hundreds of lines of context unrelated to the actual diff review.
- **Dropping `--excluded-tools skill`.** A pass can then call `/second-opinion` itself and launch a nested review on another model, billed on top.
- **Calling `copilot` by hand instead of `run`.** `run` is the one place the prompt, the flags, the timeout and the parse agree. A hand-built call drifts from all four - and piping the diff into `-p` risks shell-escape issues and prompt-size limits.
- **Copying Copilot's patch verbatim.** Copilot's `Suggestion` is a direction; Claude writes the actual edit. Verbatim copies skip Claude's knowledge of the codebase's idiomatic patterns and accepted decisions.
- **Adding `Co-Authored-By: Copilot` to fix commits.** Fixes derived from Copilot's review are Claude's edits informed by Copilot's review - same as a human reviewer's comment. No tooling attribution needed.
- **Running `/second-opinion` after a destructive history rewrite (soft-reset).** Review-driven fixes after a soft-reset need a second reset cycle to re-cut clean commits. Run the review *before* any history rewrite so fixes land in the WIP state and get consolidated for free.

## Example invocations

- `/second-opinion` - review against the merge-base with the trunk (autodetected in Phase 1)
- `/second-opinion abc1234` - review against an arbitrary commit
- `/second-opinion model gpt-6-sol` - use the premium model for a security-sensitive branch
- "Get a second opinion before I push" - same as `/second-opinion`

## Compounding loop

`REVIEW-BRIEF.md` is **git-tracked** so it compounds across runs. Two triggers update it:

1. **Copilot keeps flagging an intentional pattern** -> add it to the "do NOT flag" section.
2. **Copilot misses a class of bug repeatedly** -> add the relevant focus area or paired-file mapping.
