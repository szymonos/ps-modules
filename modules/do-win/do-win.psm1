. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/forms.ps1
. $PSScriptRoot/Functions/winget.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-CommandSource'
        'Get-DiskUsage'
        'New-File'
        # forms
        'Get-FileName'
        'Get-FolderPath'
        # winget
        'Get-WingetResult'
        'Invoke-WingetUpgrade'
    )
    Variable = @()
    Alias  = @(
        'du'
        'touch'
        'which'
    )
}

Export-ModuleMember @exportModuleMemberParams
