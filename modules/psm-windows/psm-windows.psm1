$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        'Invoke-CommandRetry'
        'Test-IsAdmin'
        'Update-SessionEnvironmentPath'
    )
    Variable = @()
    Alias    = @(
        'refreshenvpath'
    )
}

Export-ModuleMember @exportModuleMemberParams
