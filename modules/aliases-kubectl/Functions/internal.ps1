<#
.SYNOPSIS
Write provided kubectl with its arguments and then execute it.
You can suppress writing the kubectl by providing -Quiet as one of the arguments.
You can suppress executing the kubectl by providing -WhatIf as one of the arguments.

.PARAMETER Command
kubectl command to be executed.
.PARAMETER Xargs
kubectl arguments to be passed to the provided command.
.PARAMETER WhatIf
Do not execute the kubectl.
.PARAMETER Quiet
Do not print the kubectl string.
#>
function Invoke-WriteExecKubectl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if (-not $PsBoundParameters.Quiet) {
        # write command
        $writeCmd = , 'kubectl' + $Command + $Xargs | ForEach-Object {
            switch -Regex ($_) {
                "'" {
                    "`"$_`""
                    break
                }
                '\s|"' {
                    "'$_'"
                    break
                }
                Default {
                    $_
                    break
                }
            }
        } | Join-String -Separator ' '
        Write-Host $writeCmd -ForegroundColor Magenta
    }

    if (-not $PsBoundParameters.WhatIf) {
        # execute command
        Write-Debug "Invoke-WriteExecKubectl.Command: $cmnd"
        Write-Debug "Invoke-WriteExecKubectl.Xargs: $Xargs"
        & kubectl @Command @Xargs
    }
}


function Build-KubectlCommand {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('get', 'describe', 'delete')]
        [string[]]$Verb,

        [Parameter(Mandatory)]
        [ValidateSet('Pod', 'Service', 'Namespace')]
        [string[]]$Kind,

        [Parameter(Mandatory, ParameterSetName = 'pod')]
        [string]$Pod,

        [Parameter(Mandatory, ParameterSetName = 'service')]
        [string]$Service,

        [Parameter(Mandatory, ParameterSetName = 'namespace')]
        [Parameter(ParameterSetName = 'pod')]
        [Parameter(ParameterSetName = 'service')]
        [string]$Namespace,

        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    begin {
        # build command
        $cmnd = [System.Collections.Generic.List[string]]::new()
        $cmnd.AddRange([string[]]@($PSBoundParameters.Verb, "$($PSBoundParameters.Kind.ToLower())s"))
        @('Verb', 'Kind').ForEach({ $PSBoundParameters.Remove($_) | Out-Null })

        # build parameters
        if ($PSBoundParameters.Pod) {
            $cmnd.Add($Pod)
            $PSBoundParameters.Remove('Pod') | Out-Null
        } elseif ($PSBoundParameters.Service) {
            $cmnd.Add($Service)
            $PSBoundParameters.Remove('Service') | Out-Null
        }
        if ($PSBoundParameters.Namespace) {
            if ($Kind -ne 'Namespace') {
                $cmnd.AddRange([string[]]@('--namespace', $Namespace))
            }
            $PSBoundParameters.Remove('Namespace') | Out-Null
        }
    }

    process {
        Write-Debug "Build-KubectlCommand.Command: $cmnd"
        Write-Debug "Build-KubectlCommand.PSBoundParameters:`n$PSBoundParameters"
        Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
    }
}
