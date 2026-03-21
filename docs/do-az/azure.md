# :material-cloud-cog: Azure Core

Functions for Azure context management, authentication, Key Vault operations, networking,
and AKS credential handling.

## :material-account-key: Context & Auth

| Function               | Alias | Description             |
| ---------------------- | ----- | ----------------------- |
| `Connect-AzContext`    |       | Set/connect Az context  |
| `Get-AzCtx`            |       | Get context properties  |
| `Get-MsoToken`         |       | Get OAuth2 access token |
| `Set-SubscriptionMenu` | `ssm` | Set subscription menu   |

## :material-key-variant: Key Vault

| Function                        | Description                 |
| ------------------------------- | --------------------------- |
| `Get-KeyVaultCertificate`       | Get cert as X509 collection |
| `Get-KeyVaultSecret`            | Get secret (auto-policy)    |
| `Set-KeyVaultSecret`            | Set secret (auto-policy)    |
| `Set-AzKeyVaultAccessPolicyApi` | Set policy via REST API     |

## :material-lan: Networking

| Function              | Description                   |
| --------------------- | ----------------------------- |
| `Get-VirtualNetwork`  | Get VNet details from AzGraph |
| `Get-PrivateEndpoint` | Get PE by name, VNet, IP      |

## :material-kubernetes: AKS

| Function                     | Alias      | Description           |
| ---------------------------- | ---------- | --------------------- |
| `Get-AksCredential`          |            | Get AKS kubeconfig    |
| `Set-AksFederatedCredential` | `setfcaks` | Create federated cred |

## :material-tab: Completers

| Function                | Description                |
| ----------------------- | -------------------------- |
| `ArgAzGetSubscriptions` | Tab-complete subscriptions |
