$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        'Get-SysInfo'
        'Format-Duration'
        'Invoke-CommandRetry'
        'New-File'
        'Test-IsAdmin'
        'Update-SessionEnvironmentPath'
    )
    Variable = @()
    Alias    = @(
        'gsi'
        'refreshenvpath'
        'touch'
        'which'
    )
}

Export-ModuleMember @exportModuleMemberParams
