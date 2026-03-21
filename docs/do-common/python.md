# :material-language-python: Python

Functions for managing Python virtual environments across venv, conda, and uv toolchains.
Also includes a helper for fixing certifi certificate bundles from SSL chains.

| Function                     | Alias      | Description       |
| ---------------------------- | ---------- | ----------------- |
| `Invoke-CertifiFixFromChain` | `fxcertpy` | Fix certifi certs |
| `Invoke-VenvActivate`        | `iva`      | Activate venv     |
| `Invoke-VenvDeactivate`      | `ivd`      | Deactivate venv   |
| `Invoke-CondaSetup`          | `ics`      | Manage conda envs |
| `Invoke-PySetup`             | `ips`      | Setup Python venv |
| `Invoke-UvSetup`             | `ius`      | Manage uv envs    |

!!! tip
    Use `iva` to activate and `ivd` to deactivate - works with venv, conda, and uv environments.
