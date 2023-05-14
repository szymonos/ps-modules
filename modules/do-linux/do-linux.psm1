. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-SysInfo'
        'Invoke-Sudo'
        'Invoke-SudoPS'
        'Invoke-FixExecutableBit'
    )
    Variable = @()
    Alias    = @(
        # common
        'gsys'
        '_'
        'sps'
        'feb'
    )
}

Export-ModuleMember @exportModuleMemberParams
