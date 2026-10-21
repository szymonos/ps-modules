#!/usr/bin/env -S uv run --script
# /// script
# requires-python = "~=3.14.0"
# dependencies = []
# ///
"""
Review brief management for the /second-opinion skill.

Five subcommands:
  check    - verify REVIEW-BRIEF.md repo tag matches current repo
  discover - scan repo for context to generate/update the brief
  base     - resolve the trunk and the diff base; exit 3 when there is nothing to review
  run      - base + a Copilot pass per lens (logic, inputs, impact), merged; exit 3 at parity
  parse    - parse Copilot's raw output into structured JSON findings

Usage:
    scripts/review_brief.py check
    scripts/review_brief.py discover
    scripts/review_brief.py base              # merge-base with the trunk
    scripts/review_brief.py base <commit>     # an explicit base instead
    scripts/review_brief.py run                   # review since the merge-base
    scripts/review_brief.py run <commit> --model gpt-6-sol
    scripts/review_brief.py parse <raw-output-file>
    echo "<copilot output>" | scripts/review_brief.py parse -
"""

from __future__ import annotations

import argparse
import contextlib
import fnmatch
import json
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

BRIEF_FILENAME = "REVIEW-BRIEF.md"
CONTEXT_FILES = [
    ("claude_md", "CLAUDE.md"),
    ("agents_md", "AGENTS.md"),
    ("architecture_md", "ARCHITECTURE.md"),
    ("readme", "README.md"),
    ("contributing", "CONTRIBUTING.md"),
]
SKIP_DIRS = {
    ".git",
    "node_modules",
    "dist",
    "build",
    "target",
    ".venv",
    "venv",
    "vendor",
    "__pycache__",
    "site",
}
MAX_CONTEXT_LINES = 80
TRUNK_CANDIDATES = ("main", "master", "trunk", "prod")
GIT_TIMEOUT = 30
EXIT_PARITY = 3
EXIT_NO_COPILOT = 4
#: Where VS Code Server installs the Copilot CLI, outside PATH.
COPILOT_FALLBACK = (
    Path.home() / ".vscode-server/data/User/globalStorage/github.copilot-chat/copilotCli/copilot"
)
DEFAULT_MODEL = "gpt-6-luna"
PREMIUM_MODEL = "gpt-6-sol"
#: Changed lines of code past which a diff gets the premium reviewer even when it
#: touches no trigger path.
COMPLEX_LINES = 1200
NON_CODE = ("*.md", "*.lock", "*.txt", "*.svg", "*.png")
#: A review of a large diff takes minutes; past this it is hung, not thinking.
COPILOT_TIMEOUT = 1200
#: Seconds a timed-out pass gets to exit on SIGTERM before SIGKILL.
KILL_GRACE = 5


def _find_brief(start: Path | None = None) -> Path | None:
    """Walk up from start to find REVIEW-BRIEF.md."""
    if start is None:
        start = Path(__file__).resolve().parent.parent
    brief = start / BRIEF_FILENAME
    if brief.exists():
        return brief
    for parent in start.parents:
        candidate = parent / ".claude" / "skills" / "second-opinion" / BRIEF_FILENAME
        if candidate.exists():
            return candidate
    return None


def _read_frontmatter(path: Path) -> dict[str, str]:
    """Extract YAML frontmatter key-value pairs from a markdown file."""
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    fm = text[4:end]
    result: dict[str, str] = {}
    for line in fm.splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            result[key.strip()] = value.strip().strip('"').strip("'")
    return result


def _get_current_repo() -> str | None:
    """Get current repo's nameWithOwner via gh CLI."""
    try:
        result = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return None


def _read_head(path: Path, max_lines: int = MAX_CONTEXT_LINES) -> str | None:
    """Read up to max_lines from a file, or None if it doesn't exist."""
    if not path.exists():
        return None
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        return "\n".join(lines[:max_lines])
    except OSError:
        return None


def _contains(root: Path, pattern: str, *, directory: bool = False) -> bool:
    """Whether a file (or directory) matching pattern sits under root, skipping SKIP_DIRS."""
    if not root.is_dir():
        return False
    for _, dirnames, filenames in os.walk(root):
        if any(fnmatch.fnmatchcase(n, pattern) for n in (dirnames if directory else filenames)):
            return True
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
    return False


def _detect_stacks(root: Path) -> list[str]:
    """Quick stack detection (subset of bootstrap-hooks/detect_stack.py)."""
    stacks: list[str] = []
    markers = {
        "python": ["pyproject.toml", "requirements.txt", "setup.py"],
        "javascript": ["package.json"],
        "go": ["go.mod"],
        "rust": ["Cargo.toml"],
        "java": ["pom.xml", "build.gradle"],
        "ruby": ["Gemfile"],
        "docker": ["Dockerfile", "docker-compose.yml"],
        "terraform": [],
        "mkdocs": ["mkdocs.yml", "mkdocs.yaml"],
    }
    for stack, files in markers.items():
        for f in files:
            if (root / f).exists():
                stacks.append(stack)
                break

    if _contains(root, "*.tf"):
        stacks.append("terraform")
    if _contains(root, "*.sh"):
        stacks.append("shell")
    if (root / ".obsidian").exists() or _contains(root / "docs", ".obsidian", directory=True):
        stacks.append("obsidian")
    if _contains(root / "docs", "*.md"):
        stacks.append("markdown-docs")
    if (root / ".github" / "workflows").exists():
        stacks.append("github-actions")
    if (root / ".gitlab-ci.yml").exists():
        stacks.append("gitlab-ci")

    return sorted(set(stacks))


# -- Subcommands --------------------------------------------------------------


def brief_for(root: Path) -> Path | None:
    """A repo-local brief wins; the one bundled with the skill covers a repo that has none."""
    return _find_brief(root / ".claude" / "skills" / "second-opinion") or _find_brief()


def cmd_check(args: argparse.Namespace) -> int:
    """Check if REVIEW-BRIEF.md repo tag matches current repo."""
    root = Path(args.repo_root).resolve()
    brief_path = brief_for(root)

    write_to = root / ".claude" / "skills" / "second-opinion" / BRIEF_FILENAME
    # Always the repo's own copy: rewriting the bundled brief through the skill's
    # symlink would retarget it at this repo for every other repo too. A link
    # anywhere on the way - `.claude/skills`, the skill directory or the brief
    # itself - can lead out of the repo the same way, so there is no safe target then.
    shared = not write_to.resolve().is_relative_to(root)
    result: dict = {
        "brief_exists": brief_path is not None and brief_path.exists(),
        "brief_path": str(brief_path) if brief_path else None,
        "write_to": None if shared else str(write_to),
        "brief_repo": None,
        "current_repo": None,
        "match": False,
        "needs_update": False,
    }

    if not result["brief_exists"]:
        result["needs_update"] = True
        result["reason"] = "REVIEW-BRIEF.md not found"
        json.dump(result, sys.stdout, indent=2)
        print()
        return 1

    fm = _read_frontmatter(brief_path)
    result["premium_triggers"] = len(premium_globs(brief_path.read_text(encoding="utf-8")))
    result["brief_repo"] = fm.get("repo")
    result["current_repo"] = _get_current_repo()

    if result["brief_repo"] is None:
        result["needs_update"] = True
        result["reason"] = "No repo: tag in REVIEW-BRIEF.md frontmatter"
    elif result["current_repo"] is None:
        result["needs_update"] = False
        result["reason"] = "Could not determine current repo (gh CLI unavailable?)"
    elif result["brief_repo"] == result["current_repo"]:
        result["match"] = True
    else:
        result["needs_update"] = True
        brief = result["brief_repo"]
        current = result["current_repo"]
        result["reason"] = f"Repo mismatch: brief targets '{brief}', current is '{current}'"

    json.dump(result, sys.stdout, indent=2)
    print()
    return 1 if result["needs_update"] else 0


def cmd_discover(args: argparse.Namespace) -> int:
    """Scan repo for context to generate/update the brief."""
    root = Path(args.repo_root).resolve()

    context_files: dict[str, str | None] = {}
    for key, filename in CONTEXT_FILES:
        context_files[key] = _read_head(root / filename)

    stacks = _detect_stacks(root)
    current_repo = _get_current_repo()

    # A repo-local brief wins; the one bundled with the skill covers a repo that has none.
    brief_path = _find_brief(root / ".claude" / "skills" / "second-opinion") or _find_brief()
    existing_brief = None
    if brief_path and brief_path.exists():
        existing_brief = brief_path.read_text(encoding="utf-8", errors="replace")

    result = {
        "repo": current_repo,
        "root": str(root),
        "stacks": stacks,
        "context_files": {k: v for k, v in context_files.items() if v is not None},
        "existing_brief": existing_brief,
    }

    json.dump(result, sys.stdout, indent=2)
    print()
    return 0


def _git(root: Path, *args: str) -> tuple[int, str]:
    """Run git in *root*; return its exit code and stripped stdout."""
    try:
        result = subprocess.run(
            ["git", *args], cwd=root, capture_output=True, text=True, timeout=GIT_TIMEOUT
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return 1, ""
    return result.returncode, result.stdout.strip()


def _trunk_name(root: Path) -> str | None:
    """The default branch: origin/HEAD, then GitHub, then the usual names."""
    code, ref = _git(root, "symbolic-ref", "--short", "refs/remotes/origin/HEAD")
    if code == 0 and ref:
        return ref.removeprefix("origin/")
    try:
        result = subprocess.run(
            ["gh", "repo", "view", "--json", "defaultBranchRef", "-q", ".defaultBranchRef.name"],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    for name in TRUNK_CANDIDATES:
        for ref in (f"refs/heads/{name}", f"refs/remotes/origin/{name}"):
            if _git(root, "show-ref", "--verify", "--quiet", ref)[0] == 0:
                return name
    return None


def _snapshot(root: Path) -> str | None:
    """
    A commit of the working tree on top of HEAD, untracked files included, or None if clean.

    Built through a scratch index with commit-tree, so no ref, index or file moves and
    nothing needs undoing. Raises CalledProcessError when git refuses.
    """
    code, status = _git(root, "status", "--porcelain", "--untracked-files=all")
    if code != 0:
        raise subprocess.CalledProcessError(code, "git status", stderr="git status failed")
    if not status:
        return None
    with tempfile.TemporaryDirectory() as scratch:
        env = {
            **os.environ,
            "GIT_INDEX_FILE": str(Path(scratch) / "index"),
            "GIT_AUTHOR_NAME": "second-opinion",
            "GIT_AUTHOR_EMAIL": "second-opinion@localhost",
            "GIT_COMMITTER_NAME": "second-opinion",
            "GIT_COMMITTER_EMAIL": "second-opinion@localhost",
        }

        def git(*args: str) -> str:
            return subprocess.run(
                ["git", *args],
                cwd=root,
                env=env,
                capture_output=True,
                text=True,
                timeout=GIT_TIMEOUT,
                check=True,
            ).stdout.strip()

        # Starting from the real index keeps what `add -A` cannot rebuild, like a
        # force-added ignored file.
        code, index = _git(root, "rev-parse", "--git-path", "index")
        if code == 0 and (root / index).is_file():
            shutil.copyfile(root / index, env["GIT_INDEX_FILE"])
        else:
            git("read-tree", "HEAD")
        git("add", "-A")
        return git("commit-tree", git("write-tree"), "-p", "HEAD", "-m", "uncommitted changes")


def resolve_base(root: Path, commit: str | None) -> dict:
    """
    Resolve the diff base: an explicit commit, or the merge-base with the trunk.

    The trunk resolves to a local branch when there is one and to origin/<name>
    otherwise, because CI checkouts often have only the remote-tracking ref.
    Uncommitted work is reviewed too: `head` is then a snapshot commit of the
    working tree and `uncommitted` is true. `error` is set when either cannot be
    resolved; `parity` when there is nothing past the base, committed or not.
    """
    result: dict = {"trunk": None, "trunk_ref": None, "base": None, "head": None}
    if commit:
        code, base = _git(root, "rev-parse", "--verify", f"{commit}^{{commit}}")
        if code != 0:
            return {**result, "error": f"{commit!r} is not a commit here"}
    else:
        trunk = _trunk_name(root)
        if trunk is None:
            return {
                **result,
                "error": "could not resolve the trunk; run: git remote set-head origin -a",
            }
        result["trunk"] = trunk
        if _git(root, "show-ref", "--verify", "--quiet", f"refs/heads/{trunk}")[0] == 0:
            result["trunk_ref"] = trunk
        elif _git(root, "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{trunk}")[0] == 0:
            result["trunk_ref"] = f"origin/{trunk}"
        else:
            return {
                **result,
                "error": f"trunk {trunk!r} has no local or remote ref;"
                f" run: git fetch origin {trunk}",
            }
        code, base = _git(root, "merge-base", result["trunk_ref"], "HEAD")
        if code != 0:
            return {**result, "error": f"no merge-base between {result['trunk_ref']} and HEAD"}

    result["base"] = base
    try:
        snapshot = _snapshot(root)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
        detail = getattr(exc, "stderr", "") or ""
        return {**result, "error": f"could not snapshot uncommitted changes: {detail}".strip()}
    head = snapshot or _git(root, "rev-parse", "HEAD")[1]
    result["head"] = head
    result["uncommitted"] = snapshot is not None
    result["commits"] = int(_git(root, "rev-list", "--count", f"{base}..HEAD")[1] or 0)
    result["diffstat"] = _git(root, "diff", "--shortstat", f"{base}..{head}")[1]
    code = _git(root, "diff", "--quiet", f"{base}..{head}")[0]
    if code not in (0, 1):
        return {**result, "error": f"git diff {base}..{head} failed"}
    result["parity"] = code == 0
    return result


def _emit(result: dict) -> None:
    json.dump(result, sys.stdout, indent=2)
    print()


def cmd_base(args: argparse.Namespace) -> int:
    """Print the diff base. Exit 3 means nothing past it, committed or not: do not review."""
    result = resolve_base(Path(args.repo_root).resolve(), args.commit)
    _emit(result)
    if "error" in result:
        return 1
    return EXIT_PARITY if result["parity"] else 0


LENSES = {
    "logic": (
        "Focus: logic defects inside the changed lines. Trace every branch of each "
        "changed function: wrong conditions, off-by-one, identifiers that can collide, "
        "state mutated or deleted before a step that can fail, ignored exit codes and "
        "return values, gates and limits some input bypasses. Read code outside the diff "
        "only to confirm a finding."
    ),
    "inputs": (
        "Focus: hostile and degenerate input to the changed code. For every value it "
        "accepts - CLI arguments, JSON and YAML fields, files it parses - try the wrong "
        "type, empty, missing, zero, negative, duplicate, and an output path that aliases "
        "an input. Report each one that raises a traceback instead of a clean error, is "
        "silently accepted, or loses data. Also report any check that can report success "
        "after checking nothing, any error that exits with a code other than the one "
        "documented, and any write that destroys the previous file when it fails midway. "
        "Run code only when it touches nothing outside this checkout: no network, no "
        "credentials, no --apply or other live-write flag, no writes elsewhere. For "
        "anything else, reason from the source."
    ),
    "impact": (
        "Focus: what the change breaks outside the diff. List every function, "
        "parameter, attribute, flag, file name, exit code and documented behaviour the "
        "diff adds, renames, removes or changes. For each, search the whole repo with "
        "rg - callers, tests (including ones that build the object by hand), docs, "
        "SKILL.md files, READMEs, tables, CI workflows - and report every place that no "
        "longer agrees with the new code, including a document contradicting itself. "
        "Check each new subprocess or network call has a timeout and a handled failure. "
        "Skip defects that need no context outside the changed lines; other passes "
        "cover those."
    ),
}


def premium_globs(brief_text: str) -> list[str]:
    """Backticked globs listed under the brief's `## Premium review triggers`."""
    section = re.search(r"^## Premium review triggers\n(.*?)(?=^## |\Z)", brief_text, re.M | re.S)
    return re.findall(r"^- `([^`]+)`", section.group(1), re.M) if section else []


def choose_model(numstat: str, globs: list[str]) -> dict:
    """
    Pick the reviewer from `git diff --numstat --no-renames` output.

    fnmatch's `*` also matches `/`, so `dir/*` covers the whole subtree.
    """
    sensitive: list[str] = []
    code_lines = 0
    for line in numstat.splitlines():
        added, deleted, path = line.split("\t", 2)
        if any(fnmatch.fnmatchcase(path, g) for g in globs):
            sensitive.append(path)
        if added == "-" or any(fnmatch.fnmatchcase(path, p) for p in NON_CODE):
            continue
        code_lines += int(added) + int(deleted)
    reasons = []
    if sensitive:
        reasons.append(f"touches trigger paths: {', '.join(sensitive)}")
    if code_lines > COMPLEX_LINES:
        reasons.append(f"{code_lines} changed lines of code (> {COMPLEX_LINES})")
    return {
        "model": PREMIUM_MODEL if reasons else DEFAULT_MODEL,
        "reasons": reasons,
        "code_lines": code_lines,
    }


def copilot_command(
    brief: Path,
    diff_range: str,
    model: str,
    lens: str,
    intent: str | None = None,
    files: Sequence[str] = (),
    binary: str = "copilot",
) -> list[str]:
    """The non-interactive Copilot review call; the prompt makes it run git diff itself."""
    paths = f" -- {shlex.join(files)}" if files else ""
    prompt = (
        f"Read {brief}, then review the changes in git diff {diff_range}{paths}. Run "
        f"git diff --stat {diff_range}{paths} first, then the full diff. {LENSES[lens]} "
        "Before reporting, re-read the code each finding rests on and drop any you "
        "cannot confirm. Output findings using the format and severities specified in "
        "the brief."
    )
    if intent:
        prompt += (
            "\n\nThe author's stated intent for this change follows. Use it to tell "
            "deliberate behaviour from accidental behaviour. Still report code, docs "
            "or tests that disagree with it or with each other.\n\n" + intent
        )
    return [
        binary,
        "-p",
        prompt,
        "-s",
        "--model",
        model,
        "--no-custom-instructions",
        "--excluded-tools",
        "skill",
        "--allow-all-tools",
    ]


def _run_group(cmd: list[str], *, cwd: Path, timeout: int) -> subprocess.CompletedProcess:
    """
    subprocess.run in a session of its own, killed whole on timeout.

    subprocess.run kills only Copilot, leaving the tools it launched running in a
    clone that is about to be removed. POSIX only: Windows has no os.killpg.
    """
    with subprocess.Popen(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        start_new_session=True,
    ) as proc:
        try:
            out, err = proc.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            deadline = time.monotonic() + KILL_GRACE
            _signal_group(proc.pid, signal.SIGTERM)
            with contextlib.suppress(subprocess.TimeoutExpired):
                proc.communicate(timeout=KILL_GRACE)
            # A tool that redirected its output outlives the pipes; give it the
            # rest of the grace period for its TERM handler.
            while time.monotonic() < deadline and _signal_group(proc.pid, 0):
                time.sleep(0.1)
            _signal_group(proc.pid, signal.SIGKILL)
            with contextlib.suppress(subprocess.TimeoutExpired):
                proc.communicate(timeout=KILL_GRACE)
            raise
    return subprocess.CompletedProcess(cmd, proc.returncode, out, err)


def _signal_group(pgid: int, sig: int) -> bool:
    """Send sig to the process group; False once the group has no process left."""
    try:
        os.killpg(pgid, sig)
    except ProcessLookupError:
        return False
    return True


def _review(workdir: Path, brief: Path, diff_range: str, model: str, lens: str, args) -> dict:
    """One lens pass in its own clone: its raw output file and findings, or what stopped it."""
    try:
        done = _run_group(
            copilot_command(brief, diff_range, model, lens, args.intent, args.files, args.copilot),
            cwd=workdir,
            timeout=args.timeout,
        )
    except subprocess.TimeoutExpired:
        return {"lens": lens, "error": f"copilot gave no answer in {args.timeout}s"}
    except OSError as exc:
        return {"lens": lens, "error": f"could not start copilot: {exc}"}
    if done.returncode != 0:
        return {
            "lens": lens,
            "error": f"copilot exited {done.returncode}",
            "stderr": done.stderr[-2000:],
        }
    with tempfile.NamedTemporaryFile(
        "w", prefix=f"second-opinion-{lens}-", suffix=".md", delete=False, encoding="utf-8"
    ) as f:
        f.write(done.stdout)
    parsed = parse_findings(done.stdout)
    if not (parsed["count"] or parsed.get("clean") or parsed.get("unparsed")):
        return {
            "lens": lens,
            "raw": f.name,
            "error": "copilot answered with neither findings nor 'No findings.'",
        }
    return {"lens": lens, "workdir": str(workdir), "raw": f.name, **parsed}


def merge_findings(passes: list[dict], root: Path | None = None) -> list[dict]:
    """
    Every pass's findings, tagged with its lens, renumbered F-001.. and repo-relative.

    Duplicates are left in: line proximity folded unrelated findings together and
    dropped one, so telling a shared root cause apart is left to the reader.
    """
    merged = [
        {**finding, "lens": done["lens"]}
        for done in passes
        for finding in done.get("findings", [])
    ]
    roots = [str(r) for r in [root, *(p.get("workdir") for p in passes)] if r]
    for n, finding in enumerate(merged, 1):
        finding["id"] = f"F-{n:03d}"
        prefix = next((r for r in roots if finding["file"].startswith(f"{r}/")), None)
        if prefix:
            finding["file"] = finding["file"][len(prefix) + 1 :]
    return merged


def _is_file(value: str) -> bool:
    """Whether value names a file; text too long for a path is text (3.13 raises ENAMETOOLONG)."""
    try:
        return Path(value).is_file()
    except OSError:
        return False


def _run_passes(root: Path, brief: Path, diff_range: str, model: str, args) -> list[dict] | str:
    """
    Every lens pass, each in its own throwaway clone at the reviewed head, or what stopped them.

    A clone, not a linked worktree: a worktree shares refs, the stash and config with
    the user's checkout, so a pass running `git stash` or `git tag` would change it.
    `--shared` reads objects through alternates, which is what lets the snapshot
    commit check out although no ref points at it. The brief stays beside the clone,
    out of reach of whatever the reviewed tree holds at any path.
    """
    head = diff_range.split("..", 1)[1]
    with tempfile.TemporaryDirectory(prefix="second-opinion-") as scratch:
        setup = {}
        for lens in LENSES:
            clone, copy = Path(scratch) / lens, Path(scratch) / f"{lens}-{BRIEF_FILENAME}"
            steps = (
                (root, "clone", "--quiet", "--shared", "--no-checkout", str(root), str(clone)),
                (clone, "remote", "remove", "origin"),
                (clone, "checkout", "--quiet", "--detach", head),
            )
            if any(_git(cwd, *cmd)[0] != 0 for cwd, *cmd in steps):
                return f"could not create a review clone at {clone}"
            shutil.copyfile(brief, copy)
            setup[lens] = (clone, copy)
        with ThreadPoolExecutor(len(LENSES)) as pool:
            return list(
                pool.map(lambda lens: _review(*setup[lens], diff_range, model, lens, args), LENSES)
            )


def repo_relative(root: Path, files: Sequence[str]) -> list[str]:
    """
    --files with absolute paths made relative to root; ValueError for one outside it.

    git accepts an absolute in-repo pathspec, but every pass runs in a clone elsewhere.
    The last component is kept unresolved, so a symlink stays the path git tracks.
    """
    relative = []
    for f in files:
        path = Path(f)
        if path.is_absolute():
            path = path.resolve() if path.name == ".." else path.parent.resolve() / path.name
            if not path.is_relative_to(root):
                raise ValueError(f"--files {f} is outside the repo {root}")
            f = str(path.relative_to(root))
            # A leading `:` would turn the file name into pathspec magic.
            if f.startswith(":"):
                f = f"./{f}"
        relative.append(f)
    return relative


def cmd_run(args: argparse.Namespace) -> int:
    """
    Resolve the base, run one Copilot pass per lens in parallel, print merged findings.

    Each pass's raw output is kept in a temp file named in `raw`. Exit 3 is parity
    and 4 is no Copilot CLI (`skipped`); neither calls Copilot. 1 means no pass
    finished, with `error` saying what to do. A pass that failed while another
    finished is listed in `failed`, exit 0.
    """
    root = Path(args.repo_root).resolve()
    try:
        args.files = repo_relative(root, args.files)
    except ValueError as exc:
        _emit({"error": str(exc)})
        return 1
    result = resolve_base(root, args.commit)
    if "error" in result:
        _emit(result)
        return 1
    if result["parity"]:
        _emit(result)
        return EXIT_PARITY
    brief = brief_for(root)
    if brief is None:
        _emit({**result, "error": "no REVIEW-BRIEF.md; run: scripts/review_brief.py check"})
        return 1
    args.copilot = shutil.which("copilot") or (
        str(COPILOT_FALLBACK) if os.access(COPILOT_FALLBACK, os.X_OK) else None
    )
    if args.copilot is None:
        _emit(
            {**result, "skipped": "copilot CLI not found; install: https://gh.io/copilot-install"}
        )
        return EXIT_NO_COPILOT
    if args.intent and _is_file(args.intent):
        args.intent = Path(args.intent).read_text(encoding="utf-8", errors="replace")
    diff_range = f"{result['base']}..{result['head']}"
    code, scoped = _git(root, "diff", "--name-only", diff_range, "--", *(args.files or ["."]))
    if code != 0:
        _emit({**result, "error": f"git diff rejected --files {shlex.join(args.files)}"})
        return 1
    if not scoped:
        _emit(
            {
                **result,
                "parity": True,
                "reason": f"no changes under --files {shlex.join(args.files)}",
            }
        )
        return EXIT_PARITY
    if args.model:
        result["model"] = args.model
    else:
        numstat = _git(root, "diff", "--numstat", "--no-renames", diff_range, "--", *args.files)[1]
        choice = choose_model(numstat, premium_globs(brief.read_text(encoding="utf-8")))
        result.update(
            model=choice["model"], model_reasons=choice["reasons"], code_lines=choice["code_lines"]
        )
    result["brief"] = str(brief)
    passes = _run_passes(root, brief, diff_range, result["model"], args)
    if isinstance(passes, str):
        _emit({**result, "error": passes})
        return 1
    failed = [p for p in passes if "error" in p]
    if len(failed) == len(passes):
        _emit({**result, **failed[0], "failed": failed})
        return 1
    findings = merge_findings(passes, root)
    result["raw"] = {p["lens"]: p["raw"] for p in passes if "raw" in p}
    if failed:
        result["failed"] = failed
    unparsed = {p["lens"]: p["unparsed"] for p in passes if p.get("unparsed")}
    if unparsed:
        result["unparsed"] = unparsed
    _emit({**result, "findings": findings, "count": len(findings)})
    return 0


def cmd_parse(args: argparse.Namespace) -> int:
    """Parse Copilot's raw markdown output into structured JSON findings."""
    if args.input == "-":
        raw = sys.stdin.read()
    else:
        raw = Path(args.input).read_text(encoding="utf-8", errors="replace")
    _emit(parse_findings(raw))
    return 0


def parse_findings(raw: str) -> dict:
    """
    Copilot's markdown findings as `{"findings": [...], "count": N}`.

    `clean` is set only when the answer has a line made of nothing but "No findings."
    (models repeat it, as in "No findings.No findings.") and no finding heading, so
    a sentence merely ending in those words is not a clean review. `unparsed` lists
    finding headings the format did not match.
    """
    headings = re.findall(r"^###\s+F-\d+.*$", raw, re.M)
    if not headings:
        clean = any(
            line.strip() and not line.replace("No findings.", "").strip()
            for line in raw.splitlines()
        )
        return {"findings": [], "count": 0, **({"clean": True} if clean else {})}

    finding_re = re.compile(
        r"###\s+(F-\d+)\s*-\s*(?i:(bug|warning|nit))\s*-\s*(.+?)(?::(\d+))?\s*\n"
        r"(.*?)(?=\n###\s+F-|\n##\s|\Z)",
        re.DOTALL,
    )

    findings: list[dict] = []
    for m in finding_re.finditer(raw):
        body = m.group(5).strip()

        suggestion = None
        suggestion_match = re.search(
            r"\*\*Suggestion:\*\*\s*(.+?)(?=\n\n|\n###|\Z)", body, re.DOTALL
        )
        if suggestion_match:
            suggestion = suggestion_match.group(1).strip()
            description = body[: suggestion_match.start()].strip()
        else:
            description = body

        # Models write `path`:12, path:12-20, 30: and similar; keep the path and first line.
        path, _, rest = m.group(3).replace("`", "").strip().rstrip(":").partition(":")
        line = m.group(4) or next(iter(re.findall(r"\d+", rest)), None)
        finding: dict = {
            "id": m.group(1),
            "severity": m.group(2).lower(),
            "file": path.strip(),
            "description": description,
        }
        if line:
            finding["line"] = int(line)
        if suggestion:
            finding["suggestion"] = suggestion

        findings.append(finding)

    ids = {f["id"] for f in findings}
    unparsed = [h for h in headings if re.match(r"###\s+(F-\d+)", h).group(1) not in ids]
    return {
        "findings": findings,
        "count": len(findings),
        **({"unparsed": unparsed} if unparsed else {}),
    }


def main(argv: Sequence[str] | None = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Review brief management")
    parser.add_argument("--repo-root", default=".", help="Repository root (default: cwd)")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("check", help="Verify REVIEW-BRIEF.md repo tag matches current repo")
    sub.add_parser("discover", help="Scan repo for context to generate/update the brief")

    base_p = sub.add_parser("base", help="Resolve the diff base; exit 3 when nothing to review")
    base_p.add_argument("commit", nargs="?", help="explicit base commit (default: merge-base)")

    run_p = sub.add_parser("run", help="Resolve the base, run the Copilot review, parse it")
    run_p.add_argument("commit", nargs="?", help="explicit base commit (default: merge-base)")
    run_p.add_argument(
        "--model",
        help=f"default: {DEFAULT_MODEL}, or {PREMIUM_MODEL} on a trigger path or large diff",
    )
    run_p.add_argument("--intent", help="author's stated intent: a file path, or the text itself")
    run_p.add_argument("--files", nargs="+", default=[], help="review only these paths")
    run_p.add_argument(
        "--timeout", type=int, default=COPILOT_TIMEOUT, help="seconds per pass; passes run at once"
    )

    parse_p = sub.add_parser("parse", help="Parse Copilot output into JSON findings")
    parse_p.add_argument("input", help="Path to raw output file, or '-' for stdin")

    args = parser.parse_args(argv)

    commands = {
        "check": cmd_check,
        "discover": cmd_discover,
        "base": cmd_base,
        "run": cmd_run,
        "parse": cmd_parse,
    }
    return commands[args.command](args)


if __name__ == "__main__":
    raise SystemExit(main())
