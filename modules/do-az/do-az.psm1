. $PSScriptRoot/Functions/az.ps1
. $PSScriptRoot/Functions/azgraph.ps1

$exportModuleMemberParams = @{
    Function = @(
        # az
        'Connect-AzContext'
        'Get-MsoToken'
        'Set-SubscriptionMenu'
        'Invoke-AzApiRequest'
        # azgraph
        'Invoke-AzGraph'
        'Get-AzGraphSubscriptions'
        'Get-AzGraphResourceGroups'
        'Get-AzGraphResourceGroupByName'
        'Get-AzGraphResources'
        'Get-AzGraphResourceByName'
    )
    Variable = @()
    Alias    = @(
        'ssm'
    )
}

Export-ModuleMember @exportModuleMemberParams
