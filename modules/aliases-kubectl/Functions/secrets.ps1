#region functions with autocomplete
<#
.SYNOPSIS
Get kubernetes secret(s).

.PARAMETER Name
Name of the secret. Optional parameter. If not specified, all secrets in the namespace will be returned.
.PARAMETER Namespace
Specify namespace of the pod. Optional parameter.
.PARAMETER Xargs
Additional arguments to be passed to the kubectl command.
.PARAMETER WhatIf
If specified, the command will not be executed, but only written to the console.
.PARAMETER Quiet
If specified, the command will not be printed to the console.
#>
function kgsec {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetSecrets @args })]
        [string]$Name,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $param = @{
        Verb = 'get'
        Kind = 'Secret'
    }
    return Build-KubectlCommand @param @PSBoundParameters
}


<#
.SYNOPSIS
Decode and print kubernetes secret data.

.PARAMETER Name
Name of the secret to be decoded. Mandatory parameter.
.PARAMETER Namespace
Specify namespace of the secret. Optional parameter.
.PARAMETER Xargs
Additional arguments to be passed to the kubectl command.
.PARAMETER WhatIf
If specified, the command will not be executed, but only written to the console.
.PARAMETER Quiet
If specified, the command will not be printed to the console.
#>
function Get-KubectlSecretDecodedData {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ArgumentCompleter({ ArgK8sGetSecrets @args })]
        [string]$Name,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $param = @{
        Verb  = 'get'
        Kind  = 'Secret'
        Xargs = @('--output', 'json')
    }
    # convert secret to PSObject
    $secretObj = Build-KubectlCommand @param @PSBoundParameters | ConvertFrom-Json
    # decode and write secret data
    $secretObj.data.PSobject.Properties | ForEach-Object {
        Write-Host "# $($_.Name)" -ForegroundColor DarkGreen
        [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_.Value)).Trim()
    }
}
New-Alias -Name kgsecd -Value Get-KubectlSecretDecodedData
#endregion
