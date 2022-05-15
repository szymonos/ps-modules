. $PSScriptRoot/Functions.ps1

$exportModuleMemberParams = @{
    Function = @(
        'Get-ArrayIndexMenu',
        'Invoke-CommandRetry',
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
