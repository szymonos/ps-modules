. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/az.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-ArrayIndexMenu',
        'Invoke-CommandRetry',
        # az
        'Connect-AzContext',
        'Set-SubscriptionMenu',
        'Get-AzAccessToken',
        'Get-AzApiRequest'
    )
    Variable = @()
    Alias  = @(
        'ssm'
    )
}

Export-ModuleMember @exportModuleMemberParams
