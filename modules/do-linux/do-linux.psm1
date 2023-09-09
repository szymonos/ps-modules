$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-SysInfo'
        'Invoke-Sudo'
        'Invoke-SudoPS'
        'Invoke-ExecutableBitFix'
    )
    Variable = @()
    Alias    = @(
        # common
        'gsi'
        '_'
        'sps'
        'fxmod'
    )
}

Export-ModuleMember @exportModuleMemberParams
