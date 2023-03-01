. $PSScriptRoot/Functions/certs.ps1
. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/dotnet.ps1
. $PSScriptRoot/Functions/net.ps1
. $PSScriptRoot/Functions/python.ps1

$exportModuleMemberParams = @{
    Function = @(
        # certs
        'Add-CertificateProperties'
        'ConvertTo-PEM'
        'ConvertTo-X509Certificate'
        'Get-Certificate'
        # common
        'ConvertTo-UTF8LF'
        'Get-ArrayIndexMenu'
        'Get-CmdletAlias'
        'Get-SemanticVersion'
        'Format-Duration'
        'Invoke-CommandRetry'
        'New-Password'
        'Test-IsAdmin'
        # dotnet
        'Get-DotnetCurrentDirectory'
        'Set-DotnetCurrentDirectory'
        'Set-DotnetLocation'
        # net
        'ConvertFrom-CIDR'
        'Invoke-DownloadFile'
        # python
        'Invoke-CondaSetup'
        'Invoke-PySetup'
    )
    Variable = @()
    Alias    = @(
        'alias'
        'ics'
        'ips'
        'gcd'
        'scd'
        'cdd'
        'idf'
    )
}

Export-ModuleMember @exportModuleMemberParams
