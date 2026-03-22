# :material-tools: Helpers

Helper functions for kubectl version management, context switching, pod operations, and secret
decoding.

## :material-update: Version & Setup

| Function                   | Description                               |
| -------------------------- | ----------------------------------------- |
| `Get-KubectlVersion`       | Full kubectl version info (client+server) |
| `Get-KubectlClientVersion` | Client version string                     |
| `Get-KubectlServerVersion` | Server version string                     |
| `Set-KubectlLocal`         | Download kubectl matching server version  |

## :material-swap-horizontal: Context Management

| Function / Alias                    | Description    |
| ----------------------------------- | -------------- |
| `Get-KubectlContext` (`kcgctx`)     | List contexts  |
| `Set-KubectlContext` (`kcuctx`)     | Switch context |
| `Remove-KubectlContext` (`kcrmctx`) | Remove context |

## :material-folder-outline: Namespace

| Function / Alias                                   | Description   |
| -------------------------------------------------- | ------------- |
| `Set-KubectlContextCurrentNamespace` (`kcsctxcns`) | Set namespace |
| `Set-KubensContextCurrentNamespace`                | Set ns kubens |

## :material-cube-outline: Pod Operations

| Function / Alias                      | Description         |
| ------------------------------------- | ------------------- |
| `Connect-KubernetesContainer` (`kex`) | Exec into container |
| `Debug-KubernetesPod` (`kdbg`)        | Debug a pod         |
| `Get-KubectlPodContainers`            | List pod containers |
| `Get-KubectlPodLogs` (`klo`)          | Get pod logs        |

## :material-api: API Resources

| Function / Alias                                  | Description              |
| ------------------------------------------------- | ------------------------ |
| `Get-KubectlApiResourceShortNames` (`kapishorts`) | List resource shortnames |

## :material-lock-open: Secrets

| Function                       | Description        |
| ------------------------------ | ------------------ |
| `Get-KubectlSecretDecodedData` | Decode secret data |
