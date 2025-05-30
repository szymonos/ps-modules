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
        # write debug information
        Write-Debug "Invoke-WriteExecKubectl.Command`n`e[22m$cmnd`n"
        if ($PSBoundParameters.Xargs) {
            Write-Debug "Invoke-WriteExecKubectl.Xargs`n`e[22m$Xargs`n"
        }
        # execute command
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

        [switch]$WhatIf,

        [switch]$Quiet
    )

    begin {
        # write debug information
        Write-Debug "Build-KubectlCommand.PSBoundParameters`n`e[22m$($PSBoundParameters.GetEnumerator().ForEach({ "$($_.Key): $($_.Value)" }) -join "`n")`n"

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
        # write debug information
        Write-Debug "Build-KubectlCommand.Command`n`e[22m$cmnd`n"
        # execute command
        Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
    }
}
