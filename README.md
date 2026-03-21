# ps-modules

Repository with PowerShell modules I've developed over time.

Full documentation is available at [szymonos.github.io/ps-modules](https://szymonos.github.io/ps-modules/).

## 📦 Modules

### 🔀 aliases-git

Over 200 short alias functions for `git` and `gh` (GitHub CLI) commands. Every alias
prints the underlying command in magenta before running it, so you always see what's
actually executed. All aliases support `-WhatIf` (preview) and `-Quiet` (silent) switches.

#### Highlights

- **Composable naming** - aliases follow a consistent pattern (`g` + command + modifier),
  e.g. `gacp` = add all + commit + push, `gcan!` = commit --all --no-edit --amend.
- **Smart branch switching** - `gsw` resolves branches by prefix and falls back to
  the default branch when no argument is given.
- **Fetch + sync helpers** - `gmgo` and `grbo` fetch from origin, merge/rebase,
  and push automatically if the operation is clean.
- **Bulk repo management** - `grunrefresh` refreshes all repos under a directory
  (fetch, switch to default branch, merge, prune).
- **Tab completion** - completers for branch names and stash entries across 18 aliases.
- **GitHub CLI coverage** - aliases for issues, PRs, runs, and repo operations.

### ☸️ aliases-kubectl

790+ composable kubectl aliases built from a strict naming pattern:
`k` + verb + resource + output option. Once you learn the building blocks, you can
guess any alias without looking it up - e.g. `kgpoallw` = `kubectl get pods --all-namespaces --watch`.

#### Highlights

- **Composable pattern** - 7 verb prefixes x 8 resource suffixes x output modifiers
  generate the full alias set from a handful of rules.
- **Context & namespace switching** - `kcuctx` / `kcsctxcns` with tab-completed
  cluster names, contexts, and namespaces.
- **Pod operations** - `kex` to exec into a container, `kdbg` to debug a pod,
  `klo` to tail logs - all with tab completion for pod names and containers.
- **Secret decoding** - `Get-KubectlSecretDecodedData` decodes base64 secret data in one call.
- **Version matching** - `Set-KubectlLocal` downloads a kubectl binary matching your
  cluster's server version.

### ☁️ do-az

Utilities for day-to-day work with Microsoft Azure. Handles subscription context
switching, Key Vault secrets and certificates, AKS credential management, and
querying resources at scale through Azure Resource Graph.

#### Highlights

- **Subscription menu** - `Set-SubscriptionMenu` (`ssm`) gives you an interactive picker
  for switching Azure subscriptions.
- **Key Vault** - get/set secrets and retrieve certificates as X509 collections,
  with automatic access policy handling.
- **Azure Resource Graph** - query subscriptions, resource groups, and resources across
  your entire tenant with `Invoke-AzGraph` and typed wrappers.
- **AKS** - pull kubeconfig credentials and create workload identity federated
  credentials in one call.
- **Microsoft Graph** - send arbitrary MS Graph API requests and manage app federated
  credentials.

### 🧰 do-common

Foundational cross-platform module with no external dependencies. Provides the
everyday utilities that other modules (and your profile) can rely on.

#### Highlights

- **Encoding & conversion** - base64, base64url, JWT decoding, ROT13, config file
  parsing, and `json` alias for pretty-printing with jq.
- **Python environment management** - unified `iva`/`ivd` to activate/deactivate
  virtual environments across venv, conda, and uv toolchains.
- **Certificate handling** - X509 certificate inspection, PEM conversion, chain
  traversal, and certifi bundle fixing for corporate proxies.
- **Shell helpers** - `.env` file loading, interactive selection menus, password
  generation, retry with backoff, and PSReadLine history search.
- **Networking** - CIDR subnet resolution and file download utilities.

### 🐧 do-linux

Linux-focused utilities for system inspection and running commands as root
from within PowerShell - particularly handy in WSL environments.

#### Highlights

- **System info** - `gsi` prints a colorful system summary: OS, kernel, CPU,
  memory usage, WSL distro, and terminal.
- **Sudo wrappers** - `_` (Invoke-Sudo) resolves PowerShell aliases before passing
  them to sudo, so `_ gst` actually runs `sudo git status`. `sps` does the same
  but launches a pwsh subprocess for full cmdlet support.
- **Executable bit fix** - `fixmod` scans a directory tree and sets/removes the
  executable bit based on shebang presence - useful after cloning repos on Windows.
- **Makefile tab completion** - `Register-MakeCompleter` gives you tab-completed
  Makefile targets.

### 🪟 do-win

Windows-specific utilities that bring familiar Linux commands to PowerShell and
simplify system maintenance.

#### Highlights

- **Linux-like commands** - `which`, `du`, `touch`, and `gsi` (system info) work
  the way you'd expect from a Unix shell.
- **PATH refresh** - `refreshenvpath` reloads the session PATH after installing
  software, without restarting the terminal.
- **File/folder dialogs** - `Get-FileName` and `Get-FolderPath` open native Windows
  picker dialogs from the command line.
- **Winget automation** - `Invoke-WingetUpgrade` upgrades all winget packages in
  one shot, with parsed result output.
