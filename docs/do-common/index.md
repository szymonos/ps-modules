# :material-toolbox: do-common

Common cross-platform utilities for PowerShell. This is a foundational module with no external
dependencies, providing certificate handling, encoding/conversion tools, environment management,
logging, networking, and Python virtual environment helpers.

!!! note "Module Info"
    **Version:** 1.8.3 &middot; **PowerShell:** 7.0+ &middot; **Dependencies:** none

```powershell
./module_manage.ps1 'do-common' -CleanUp
```

## :material-star: Highlights

- **Encoding & conversion** - base64, base64url, JWT decoding, ROT13, config file
  parsing, and `json` alias for pretty-printing with jq.
- **Python environment management** - unified `iva`/`ivd` to activate/deactivate
  virtual environments across venv, conda, and uv toolchains.
- **Certificate handling** - X509 certificate inspection, PEM conversion, chain
  traversal, and certifi bundle fixing for corporate proxies.
- **Shell helpers** - `.env` file loading, interactive selection menus, password
  generation, retry with backoff, and PSReadLine history search.
- **Networking** - CIDR subnet resolution and file download utilities.

## :material-book-open-variant: Pages

- :material-certificate: [Certificates](certs.md) - X509 certificate handling, PEM conversion, chain inspection
- :material-console: [Common Utilities](common.md) - encoding, conversion, environment, shell helpers
- :material-file-document: [Logging](logging.md) - log file management and console/file output
- :material-web: [Networking](networking.md) - CIDR resolution and file downloads
- :material-language-python: [Python](python.md) - virtual environment management for venv, conda, and uv
