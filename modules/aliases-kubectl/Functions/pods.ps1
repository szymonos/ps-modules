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
        Xargs = @('--output', "jsonpath='{.spec.containers[*].name}'")
    }
    return (Build-KubectlCommand @param @PSBoundParameters).Split()
}
#endregion


#region alias functions
function ktop {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'kubectl top pods --use-protocol-buffers' @PSBoundParameters
}
function ktopcntr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'kubectl top pods --use-protocol-buffers --containers' @PSBoundParameters
}
#endregion
