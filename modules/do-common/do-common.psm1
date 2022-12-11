. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/net.ps1
. $PSScriptRoot/Functions/python.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Invoke-CommandRetry'
        'Get-ArrayIndexMenu'
        'Format-Duration'
        'Get-CmdletAlias'
        'New-Password'
        'Test-IsAdmin'
        # net
        'ConvertFrom-CIDR'
        # python
        'Invoke-CondaScript'
        'Invoke-PySetup'
    )
    Variable = @()
    Alias  = @(
        'alias'
        'ics'
        'ips'
    )
}

Export-ModuleMember @exportModuleMemberParams
