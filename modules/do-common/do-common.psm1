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
        'Get-CertificateOpenSSL'
        'Show-CertificateChain'
        'Show-Certificate'
        # common
        'ConvertFrom-Base64'
        'ConvertTo-Base64'
        'ConvertTo-UTF8LF'
        'Get-ArrayIndexMenu'
        'Get-CmdletAlias'
        'Get-DotEnv'
        'Get-SemanticVersion'
        'Format-Duration'
        'Invoke-CommandRetry'
        'Invoke-ExampleScriptSave'
        'New-Password'
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
        'ics'
        'ips'
    )
}

Export-ModuleMember @exportModuleMemberParams
