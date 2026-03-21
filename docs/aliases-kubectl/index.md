# :material-kubernetes: aliases-kubectl

Short alias functions for kubectl commands. Provides 790+ aliases following a consistent naming
convention, plus helper functions for context management, pod operations, and secret decoding.

!!! note "Module Info"
    **Version:** 0.11.4 (beta) &middot; **PowerShell:** 7.3+ &middot; **Dependencies:** none

```powershell
./module_manage.ps1 'aliases-kubectl' -CleanUp
```

## :material-star: Highlights

- **Composable pattern** - 7 verb prefixes x 8 resource suffixes x output modifiers
  generate the full alias set from a handful of rules.
- **Context & namespace switching** - `kcuctx` / `kcsctxcns` with tab-completed
  cluster names, contexts, and namespaces.
- **Pod operations** - `kex` to exec into a container, `kdbg` to debug a pod,
  `klo` to tail logs - all with tab completion for pod names and containers.
- **Secret decoding** - `Get-KubectlSecretDecodedData` decodes base64 secret data
  in one call.
- **Version matching** - `Set-KubectlLocal` downloads a kubectl binary matching your
  cluster's server version.

## :material-book-open-variant: Pages

- :material-format-letter-case: [Naming Conventions](conventions.md) - composable alias pattern explained
- :material-format-list-bulleted: [Aliases](aliases.md) - core operations, resource aliases, and module aliases
- :material-tools: [Helpers](helpers.md) - version management, context switching, pod operations, secrets
- :material-tab: [Completers](completers.md) - tab-completion for clusters, contexts, pods, namespaces, secrets
