# :material-graph: Graph APIs

Functions for querying Azure resources via Azure Resource Graph and interacting with
Microsoft Graph API for application management.

## :material-database-search: Azure Resource Graph

| Function                         | Description          |
| -------------------------------- | -------------------- |
| `Invoke-AzGraph`                 | Generic AzGraph      |
| `Get-AzGraphSubscription`        | Get subscriptions    |
| `Get-AzGraphResourceGroup`       | Get resource groups  |
| `Get-AzGraphResourceGroupByName` | Get RG by name       |
| `Get-AzGraphResource`            | Get resources        |
| `Get-AzGraphResourceByName`      | Get resource by name |
| `Get-AzResourceTypeApiVersions`  | Get API versions     |

## :material-microsoft: Microsoft Graph

| Function                       | Description           |
| ------------------------------ | --------------------- |
| `Invoke-MgApiRequest`          | Send MS Graph request |
| `Get-MgAppFederatedCredential` | Get federated creds   |
