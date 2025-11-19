$ErrorActionPreference = 'Stop'
# classes
. $PSScriptRoot/Classes/do-az.ps1
# functions
. $PSScriptRoot/Functions/az.ps1
. $PSScriptRoot/Functions/azgraph.ps1
. $PSScriptRoot/Functions/completers.ps1

$exportModuleMemberParams = @{
    Function = @(
        # az
        'Connect-AzContext'
        'Get-AzCtx'
        'Get-AzResourceTypeApiVersions'
        'Get-MsoToken'
        'Set-AzKeyVaultAccessPolicyApi'
        'Get-KeyVaultCertificate'
        'Get-KeyVaultSecret'
        'Set-KeyVaultSecret'
        'Get-VirtualNetwork'
        'Get-PrivateEndpoint'
        'Set-SubscriptionMenu'
        'Invoke-AzApiRequest'
        'Get-AksCredential'
        # azgraph
        'Invoke-AzGraph'
        'Get-AzGraphSubscription'
        'Get-AzGraphResourceGroup'
        'Get-AzGraphResourceGroupByName'
        'Get-AzGraphResource'
        'Get-AzGraphResourceByName'
        # completers
        'ArgAzGetSubscriptions'
        # aks
        'Set-AksFederatedCredential'
    )
    Variable = @()
    Alias    = @(
        'ssm'
        'setaksfc'
    )
}

Export-ModuleMember @exportModuleMemberParams
