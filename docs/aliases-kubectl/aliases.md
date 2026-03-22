# :material-format-list-bulleted: Kubectl Aliases

The module provides **790+** short-form alias functions for kubectl from `Functions/alias.ps1`.
See [Naming Conventions](conventions.md) for the composable pattern behind every alias.

## :material-server: Core Operations

| Alias  | Command                |
| ------ | ---------------------- |
| `kinf` | `kubectl cluster-info` |
| `kav`  | `kubectl api-versions` |
| `kcv`  | `kubectl config view`  |
| `kp`   | `kubectl proxy`        |
| `kpf`  | `kubectl port-forward` |

## :material-application-import: Apply / Delete

| Alias    | Command                |
| -------- | ---------------------- |
| `ka`     | `kubectl apply -f`     |
| `kadryc` | apply --dry-run=client |
| `kadrys` | apply --dry-run=server |
| `kak`    | `kubectl apply -k`     |
| `krmk`   | `kubectl delete -k`    |

## :material-cube-outline: Pod Resource Aliases

| Alias      | Description                |
| ---------- | -------------------------- |
| `kgpo`     | Get pods (with completion) |
| `kdpo`     | Describe pod               |
| `kgpocntr` | Get pod containers         |
| `kgporsrc` | Get pod resource requests  |
| `ktno`     | Top nodes                  |
| `ktpo`     | Top pods                   |
| `ktpocntr` | Top pod containers         |

## :material-lock: Secret Aliases

| Alias    | Description                   |
| -------- | ----------------------------- |
| `kgsec`  | Get secrets (with completion) |
| `kgsecd` | Get and decode secret data    |

## :material-cog: Module Aliases

| Alias        | Function                           |
| ------------ | ---------------------------------- |
| `kv`         | `Get-KubectlVersion`               |
| `kvc`        | `Get-KubectlClientVersion`         |
| `kvs`        | `Get-KubectlServerVersion`         |
| `kc`         | `Set-KubectlContext`               |
| `kn`         | `Set-KubectlContextCurrent..`      |
| `kex`        | `Connect-KubernetesContainer`      |
| `kdbg`       | `Debug-KubernetesPod`              |
| `klo`        | `Get-KubectlPodLogs`               |
| `kapishorts` | `Get-KubectlApiResourceShortNames` |
