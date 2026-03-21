# :material-console: Common Utilities

General-purpose shell utilities covering encoding/decoding, configuration file handling,
environment management, and .NET directory helpers.

## :material-swap-horizontal: Encoding & Conversion

| Function                  | Alias  | Description          |
| ------------------------- | ------ | -------------------- |
| `ConvertFrom-Base64`      |        | Decode base64 string |
| `ConvertTo-Base64`        |        | Encode to base64     |
| `ConvertFrom-Base64Url`   |        | Decode base64url     |
| `ConvertFrom-JWT`         |        | Decode JWT token     |
| `ConvertFrom-Cfg`         |        | Config to dictionary |
| `ConvertTo-Cfg`           |        | Dictionary to config |
| `ConvertTo-UTF8LF`        |        | Convert to UTF-8 LF  |
| `Convert-ROT13`           |        | ROT13 encode/decode  |
| `ConvertTo-JsonFormatted` | `json` | Format JSON with jq  |

## :material-console-line: Shell & Environment

| Function                   | Alias       | Description            |
| -------------------------- | ----------- | ---------------------- |
| `Get-ArrayIndexMenu`       |             | Selection menu         |
| `Get-CmdletAlias`          | `alias`     | Get cmdlet aliases     |
| `Get-DotEnv`               |             | Read .env file         |
| `Set-DotEnv`               |             | Set env from .env      |
| `Get-LogMessage`           |             | Format log message     |
| `Get-PSReadLineHistory`    | `pshistory` | PSReadLine history     |
| `Format-Duration`          |             | Human-readable time    |
| `Invoke-CommandRetry`      |             | Retry on HTTP errors   |
| `Invoke-ExampleScriptSave` | `egsave`    | Save script examples   |
| `New-Password`             |             | Generate random string |
| `Show-Object`              |             | Show object properties |
| `Test-IsAdmin`             |             | Check if elevated      |

## :material-application-brackets: CLI

| Function            | Alias  | Description            |
| ------------------- | ------ | ---------------------- |
| `Invoke-DigColored` | `digc` | Colorized `dig` output |

## :material-folder-cog: .NET Directory

| Function                     | Alias  | Description      |
| ---------------------------- | ------ | ---------------- |
| `Get-DotnetCurrentDirectory` | `swd`  | Get dotnet CWD   |
| `Set-DotnetCurrentDirectory` | `sswd` | Set dotnet CWD   |
| `Set-DotnetLocation`         | `cds`  | cd to dotnet CWD |
