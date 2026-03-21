# :material-linux: do-linux

Linux-focused utilities for system inspection and running commands as root
from within PowerShell - particularly handy in WSL environments.

!!! note "Module Info"
    **Version:** 0.6.0 (beta) &middot; **PowerShell:** 7.0+ &middot; **Dependencies:** `do-common`

```powershell
./module_manage.ps1 'do-linux' -CleanUp
```

## :material-star: Highlights

- **System info** - `gsi` prints a colorful system summary: OS, kernel, CPU,
  memory usage, WSL distro, and terminal.
- **Sudo wrappers** - `_` (Invoke-Sudo) resolves PowerShell aliases before passing
  them to sudo, so `_ gst` actually runs `sudo git status`. `sps` does the same
  but launches a pwsh subprocess for full cmdlet support.
- **Executable bit fix** - `fixmod` scans a directory tree and sets/removes the
  executable bit based on shebang presence - useful after cloning repos on Windows.
- **Makefile tab completion** - `Register-MakeCompleter` gives you tab-completed
  Makefile targets.

## :material-function: Functions

| Function                  | Alias            | Description                         |
| ------------------------- | ---------------- | ----------------------------------- |
| `Get-SysInfo`             | `gsi`            | System info from /etc/os-release    |
| `Invoke-Sudo`             | `_`              | Run commands as root                |
| `Invoke-SudoPS`           | `sps`            | Run PS cmdlets as root              |
| `Invoke-ExecutableBitFix` | `fixmod`/`fxmod` | Fix executable bit based on shebang |
| `Register-MakeCompleter`  |                  | Tab-complete Makefile targets       |
