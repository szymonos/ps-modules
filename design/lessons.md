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
