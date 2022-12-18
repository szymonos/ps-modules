. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Invoke-Sudo'
        'Invoke-SudoPS'
        'Invoke-FixExecutableBit'
        'Remove-WindowsPathInWSL'
    )
    Variable = @()
    Alias  = @(
        '_'
        'sps'
        'feb'
        'wslp'
    )
}

Export-ModuleMember @exportModuleMemberParams
