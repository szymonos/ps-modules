$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/certs.ps1
. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/dotnet.ps1
. $PSScriptRoot/Functions/net.ps1
. $PSScriptRoot/Functions/python.ps1

$exportModuleMemberParams = @{
    Function = @(
        # certs
        'Add-CertificateProperties'
        'ConvertFrom-PEM'
        'ConvertTo-PEM'
        'Get-Certificate'
        'Get-CertificateOpenSSL'
        'Get-RootCertificates'
        'Show-CertificateChain'
        'Show-Certificate'
        # common
        'ConvertFrom-Base64'
        'ConvertTo-Base64'
        'ConvertTo-UTF8LF'
        'Get-ArrayIndexMenu'
        'Get-CmdletAlias'
        'Get-DotEnv'
        'Format-Duration'
        'Invoke-CommandRetry'
        'Invoke-ExampleScriptSave'
        'New-Password'
        'Set-DotEnv'
        'Show-Object'
        'Test-IsAdmin'
        # dotnet
        'Get-DotnetCurrentDirectory'
        'Set-DotnetCurrentDirectory'
        'Set-DotnetLocation'
        # net
        'ConvertFrom-CIDR'
        'Invoke-DownloadFile'
        # python
        'Invoke-CertifiFixFromChain'
        'Invoke-CondaSetup'
        'Invoke-PySetup'
    )
    Variable = @()
    Alias    = @(
        # common
        'alias'
        'egsave'
        # dotnet
        'swd'
        'sswd'
        'cds'
        # net
        'idf'
        # python
        'fxcertpy'
        'ics'
        'ips'
    )
}

Export-ModuleMember @exportModuleMemberParams
