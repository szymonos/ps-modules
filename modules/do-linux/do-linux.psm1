. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Invoke-FixExecutableBit'
    )
    Variable = @()
    Alias  = @(
        'feb'
    )
}

Export-ModuleMember @exportModuleMemberParams
