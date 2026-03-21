# :material-tab: Completers

Tab-completion functions from `Functions/completers.ps1` that query the Kubernetes API
for live cluster data, enabling interactive argument completion.

## :material-server-network: ArgK8sGetClusters

Returns cluster names from `kubectl config view`. Completes the `-Cluster` parameter.

**Used by:**

| Function / Alias            | Description    | Source |
| --------------------------- | -------------- | ------ |
| `Set-KubectlContext` (`kc`) | Switch context | helper |

## :material-swap-horizontal: ArgK8sGetContexts

Returns context names from `kubectl config view`. Completes the `-Context` parameter.

**Used by:**

| Function / Alias            | Description    | Source |
| --------------------------- | -------------- | ------ |
| `Set-KubectlContext` (`kc`) | Switch context | helper |

## :material-folder-outline: ArgK8sGetNamespaces

Returns active namespace names from the current cluster. Completes the `-Namespace` parameter.

**Used by:**

| Function / Alias                                   | Description         | Source |
| -------------------------------------------------- | ------------------- | ------ |
| `kgpo`                                             | Get pods            | alias  |
| `kdpo`                                             | Describe pod        | alias  |
| `kgpocntr`                                         | Get pod containers  | alias  |
| `kgporsrc`                                         | Get pod resources   | alias  |
| `ktpo`                                             | Top pods            | alias  |
| `ktpocntr`                                         | Top pod containers  | alias  |
| `kgsec`                                            | Get secrets         | secret |
| `kgsecd`                                           | Decode secret data  | secret |
| `Set-KubectlContextCurrentNamespace` (`kcsctxcns`) | Set namespace       | helper |
| `Set-KubensContextCurrentNamespace`                | Set ns (kubens)     | helper |
| `Connect-KubernetesContainer` (`kex`)              | Exec into container | helper |
| `Debug-KubernetesPod` (`kdbg`)                     | Debug a pod         | helper |
| `Get-KubectlPodLogs` (`klo`)                       | Get pod logs        | helper |

## :material-cube-outline: ArgK8sGetPods

Returns running pod names from the current namespace. Namespace-aware - respects the
`-Namespace` parameter if already provided.

**Used by:**

| Function / Alias                      | Description         | Source |
| ------------------------------------- | ------------------- | ------ |
| `kgpo`                                | Get pods            | alias  |
| `kdpo`                                | Describe pod        | alias  |
| `kgpocntr`                            | Get pod containers  | alias  |
| `kgporsrc`                            | Get pod resources   | alias  |
| `ktpo`                                | Top pods            | alias  |
| `ktpocntr`                            | Top pod containers  | alias  |
| `Connect-KubernetesContainer` (`kex`) | Exec into container | helper |
| `Debug-KubernetesPod` (`kdbg`)        | Debug a pod         | helper |
| `Get-KubectlPodLogs` (`klo`)          | Get pod logs        | helper |

## :material-cube-scan: ArgK8sGetPodContainers

Returns container names for a specific pod. Requires the `-Pod` parameter to be set first,
and respects `-Namespace` if provided.

**Used by:**

| Function / Alias                      | Description         | Source |
| ------------------------------------- | ------------------- | ------ |
| `Connect-KubernetesContainer` (`kex`) | Exec into container | helper |
| `Get-KubectlPodLogs` (`klo`)          | Get pod logs        | helper |

## :material-lock: ArgK8sGetSecrets

Returns secret names from the current namespace. Namespace-aware - respects the
`-Namespace` parameter if already provided.

**Used by:**

| Function / Alias | Description        | Source |
| ---------------- | ------------------ | ------ |
| `kgsec`          | Get secrets        | secret |
| `kgsecd`         | Decode secret data | secret |
