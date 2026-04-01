# :material-text-search: Log & Reflog Helpers

Functions from `Functions/log.ps1` that return git log/reflog entries as PowerShell objects,
enabling filtering, sorting, and pipeline operations on commit history.

## :material-database: Log as Objects

| Alias   | Description                   |
| ------- | ----------------------------- |
| `gglo`  | Git log as PowerShell objects |
| `ggloa` | Git log objects --all         |
| `glom`  | Get log message               |
| `glom1` | Get first log message         |

!!! example "Pipeline usage"
    ```powershell
    gglo | Where-Object { $_.Author -match 'szymon' } | Select-Object -First 5
    ```

## :material-palette: Colored Log

| Alias    | Description                    |
| -------- | ------------------------------ |
| `ggloc`  | Git log objects colored        |
| `ggloca` | Git log objects colored --all  |
| `gglot`  | Git log objects colored --tags |

## :material-history: Reflog as Objects

| Alias  | Description                      | Analogous to |
| ------ | -------------------------------- | ------------ |
| `grlo` | Git reflog as PowerShell objects | `gglo`       |

!!! example "Pipeline usage"
    ```powershell
    grlo | Where-Object { $_.Subject -match 'checkout' } | Select-Object -First 5
    ```

## :material-palette: Colored Reflog

| Alias   | Description                | Analogous to |
| ------- | -------------------------- | ------------ |
| `grloc` | Git reflog objects colored | `ggloc`      |

## :material-magnify: Log Grep

| Alias     | Description                       |
| --------- | --------------------------------- |
| `ggrep`   | Git log objects with --grep       |
| `ggrepa`  | Git log objects with --grep --all |
| `ggrepc`  | Colored log with --grep           |
| `ggrepca` | Colored log with --grep --all     |
