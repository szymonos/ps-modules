. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Invoke-Sudo'
        'Invoke-SudoPS'
        'Invoke-FixExecutableBit'
    )
    Variable = @()
    Alias  = @(
        '_'
        'sps'
        'feb'
    )
}

Export-ModuleMember @exportModuleMemberParams
