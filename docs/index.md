# :octicons-terminal-16: ps-modules

PowerShell modules developed for streamlining development workflows.

## :material-view-module: Modules

### :material-git: [aliases-git]

Over 200 short alias functions for `git` and `gh` (GitHub CLI) commands. Every alias
prints the underlying command in magenta before running it, so you always see what's
actually executed. All aliases support `-WhatIf` (preview) and `-Quiet` (silent) switches.

### :material-kubernetes: [aliases-kubectl]

790+ composable kubectl aliases built from a strict naming pattern:
`k` + verb + resource + output option. Once you learn the building blocks, you can
guess any alias without looking it up - e.g. `kgpoallw` =
`kubectl get pods --all-namespaces --watch`.

### :material-microsoft-azure: [do-az]

Utilities for day-to-day work with Microsoft Azure. Handles subscription context
switching, Key Vault secrets and certificates, AKS credential management, and
querying resources at scale through Azure Resource Graph.

### :material-toolbox: [do-common]

Foundational cross-platform module with no external dependencies. Provides the
everyday utilities that other modules (and your profile) can rely on - encoding,
certificate handling, Python environment management, and shell helpers.

### :material-linux: [do-linux]

Linux-focused utilities for system inspection and running commands as root
from within PowerShell - particularly handy in WSL environments.

### :material-microsoft-windows: [do-win]

Windows-specific utilities that bring familiar Linux commands to PowerShell and
simplify system maintenance.

### :material-powershell: [psm-windows]

Basic functions compatible with Windows PowerShell 5.1 for environments where
PowerShell Core is not available.

[aliases-git]: aliases-git/index.md
[aliases-kubectl]: aliases-kubectl/index.md
[do-az]: do-az/index.md
[do-common]: do-common/index.md
[do-linux]: do-linux/index.md
[do-win]: do-win/index.md
[psm-windows]: psm-windows/index.md

## :material-download: Installation

Modules are managed with the `module_manage.ps1` script. It detects `CurrentUser`/`AllUsers` scope
automatically based on elevation.

```powershell
# install module
./module_manage.ps1 -Module 'do-common'

# clean up previous versions during installation
./module_manage.ps1 -Module 'do-common' -CleanUp

# remove requirements from manifest
./module_manage.ps1 -Module 'do-common' -RemoveRequirements

# delete module
./module_manage.ps1 -Module 'do-common' -Delete

# scaffold new module manifest
./module_manage.ps1 -Module 'do-test' -Create
```

## :material-powershell: Requirements

!!! info "PowerShell 7.0+"
    All modules require **PowerShell 7.0+** (Core) unless otherwise noted.
    The `psm-windows` module supports Windows PowerShell 5.1.

## :material-file-tree: Dependencies

```text
aliases-git     (standalone)
aliases-kubectl (standalone)
do-az           -> do-common, Az.Accounts, Az.ResourceGraph
do-common       (standalone)
do-linux        -> do-common
do-win          (standalone)
psm-windows     (standalone)
```
