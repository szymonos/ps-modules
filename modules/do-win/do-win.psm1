$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/forms.ps1
. $PSScriptRoot/Functions/winget.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-CommandSource'
        'Get-DiskUsage'
        'Get-SysInfo'
        'New-File'
        'Update-SessionEnvironmentPath'
        # forms
        'Get-FileName'
        'Get-FolderPath'
        # winget
        'Get-WingetResult'
        'Invoke-WingetUpgrade'
    )
    Variable = @()
    Alias    = @(
        # common
        'du'
        'gsi'
        'refreshenvpath'
        'touch'
        'which'
    )
}

Export-ModuleMember @exportModuleMemberParams
