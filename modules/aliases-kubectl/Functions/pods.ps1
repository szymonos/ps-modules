#region functions with autocomplete
<#
.SYNOPSIS
Get kubernetes pod(s).

.PARAMETER Pod
Name of the pod.
.PARAMETER Namespace
Specify namespace of the pod.
#>
function kgpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

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
        Kind = 'Pod'
    }
    return Build-KubectlCommand @param @PSBoundParameters
}


function kdpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

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
        Verb = 'describe'
        Kind = 'Pod'
    }
    return Build-KubectlCommand @param @PSBoundParameters
}


function kgpocntr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    #
    $param = @{
        Verb  = 'get'
        Kind  = 'Pod'
        Xargs = @('--output', 'jsonpath={.spec.containers[*].name}')
    }
    return (Build-KubectlCommand @param @PSBoundParameters).Split()
}
#endregion


#region alias functions
function ktno {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('top', 'nodes', '--use-protocol-buffers')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ktpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('top', 'pods', '--use-protocol-buffers')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ktpocntr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('top', 'pods', '--use-protocol-buffers', '--containers')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
#endregion
