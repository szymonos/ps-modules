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
        'Invoke-FixExecutableBit'
        # net
        'ConvertFrom-CIDR'
        # python
        'Invoke-CondaScript'
        'Invoke-PySetup'
    )
    Variable = @()
    Alias  = @(
        'alias'
        'feb'
    )
}

Export-ModuleMember @exportModuleMemberParams
