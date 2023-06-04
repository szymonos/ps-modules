. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-OsRelease'
        'Get-SysInfo'
        'Invoke-Sudo'
        'Invoke-SudoPS'
        'Invoke-ExecutableBitFix'
    )
    Variable = @()
    Alias    = @(
        # common
        'osr'
        'gsi'
        '_'
        'sps'
        'fxmod'
    )
}

Export-ModuleMember @exportModuleMemberParams
