$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        'Invoke-CommandRetry'
        'Join-Str'
        'Test-IsAdmin'
        'Update-SessionEnvironmentPath'
    )
    Variable = @()
    Alias    = @(
        'refreshenvpath'
    )
}

Export-ModuleMember @exportModuleMemberParams
