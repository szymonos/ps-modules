# :material-microsoft-azure: do-az

Utilities for working with Microsoft Azure - context management, Key Vault, AKS, virtual networking,
and querying resources via Azure Resource Graph and Microsoft Graph APIs.

!!! note "Module Info"
    **Version:** 1.22.3 &middot; **PowerShell:** 7.0+ &middot; **Dependencies:** `do-common`, `Az.Accounts`, `Az.ResourceGraph`

```powershell
./module_manage.ps1 'do-az' -CleanUp -RemoveRequirements
```

## :material-star: Highlights

- **Subscription menu** - `Set-SubscriptionMenu` (`ssm`) gives you an interactive
  picker for switching Azure subscriptions.
- **Key Vault** - get/set secrets and retrieve certificates as X509 collections,
  with automatic access policy handling.
- **Azure Resource Graph** - query subscriptions, resource groups, and resources
  across your entire tenant with `Invoke-AzGraph` and typed wrappers.
- **AKS** - pull kubeconfig credentials and create workload identity federated
  credentials in one call.
- **Microsoft Graph** - send arbitrary MS Graph API requests and manage app
  federated credentials.

## :material-book-open-variant: Pages

- :material-cloud-cog: [Azure Core](azure.md) - context, authentication, Key Vault, networking, AKS
- :material-graph: [Graph APIs](graph.md) - Azure Resource Graph and Microsoft Graph queries
