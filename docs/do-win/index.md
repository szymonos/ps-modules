# :material-microsoft-windows: do-win

Windows-specific utilities that bring familiar Linux commands to PowerShell and
simplify system maintenance.

!!! note "Module Info"
    **Version:** 0.8.0 (beta) &middot; **PowerShell:** 7.0+ &middot; **Dependencies:** none

```powershell
./module_manage.ps1 'do-win' -CleanUp
```

## :material-star: Highlights

- **Linux-like commands** - `which`, `du`, `touch`, and `gsi` (system info) work
  the way you'd expect from a Unix shell.
- **PATH refresh** - `refreshenvpath` reloads the session PATH after installing
  software, without restarting the terminal.
- **File/folder dialogs** - `Get-FileName` and `Get-FolderPath` open native Windows
  picker dialogs from the command line.
- **Winget automation** - `Invoke-WingetUpgrade` upgrades all winget packages in
  one shot, with parsed result output.

## :material-console: Common

| Function                        | Alias            | Description    |
| ------------------------------- | ---------------- | -------------- |
| `Get-CommandSource`             | `which`          | Command source |
| `Get-DiskUsage`                 | `du`             | Folder sizes   |
| `Get-SysInfo`                   | `gsi`            | System info    |
| `New-File`                      | `touch`          | Create a file  |
| `Update-SessionEnvironmentPath` | `refreshenvpath` | Refresh PATH   |

## :material-form-select: Forms

| Function         | Description           |
| ---------------- | --------------------- |
| `Get-FileName`   | Open file dialog      |
| `Get-FolderPath` | Folder browser dialog |

## :material-package-up: Winget

| Function               | Description                  |
| ---------------------- | ---------------------------- |
| `Get-WingetResult`     | Parse winget upgrade results |
| `Invoke-WingetUpgrade` | Upgrade all packages         |
