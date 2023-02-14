. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/dotnet.ps1
. $PSScriptRoot/Functions/net.ps1
. $PSScriptRoot/Functions/python.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-ArrayIndexMenu'
        'Get-CmdletAlias'
        'Get-SemanticVersion'
        'Format-Duration'
        'Invoke-CommandRetry'
        'New-Password'
        'Test-IsAdmin'
        # dotnet
        'Get-DotnetCurrentDirectory'
        'Set-DotnetCurrentDirectory'
        'Set-DotnetLocation'
        # net
        'ConvertFrom-CIDR'
        # python
        'Invoke-CondaSetup'
        'Invoke-PySetup'
    )
    Variable = @()
    Alias  = @(
        'alias'
        'ics'
        'ips'
        'gcd'
        'scd'
        'cdd'
    )
}

Export-ModuleMember @exportModuleMemberParams
