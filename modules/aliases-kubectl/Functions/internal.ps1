<#
.SYNOPSIS
Write provided command with its arguments and then execute it.
You can suppress writing the command by providing -Quiet as one of the arguments.
You can suppress executing the command by providing -WhatIf as one of the arguments.

.PARAMETER Command
Command to be executed.
.PARAMETER Arguments
Command arguments to be passed to the provided command.
.PARAMETER WhatIf
Do not execute the command.
.PARAMETER Quiet
Do not print the command string.
#>
function Invoke-WriteExecCommand {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    begin {
        # build command
        $sb = [System.Text.StringBuilder]::new($Command)
        if ($PSBoundParameters.Xargs) {
            $Xargs | ForEach-Object {
                $arg = $_ -match '\s|@' ? "'$_'" : $_
                $sb.Append(" $arg") | Out-Null
            }
        }
        # get command string
        $cmnd = $sb.ToString()
    }

    process {
        if (-not $PSBoundParameters.Quiet) {
            # write command
            Write-Host $cmnd -ForegroundColor Magenta
        }
        if (-not $PSBoundParameters.WhatIf) {
            # execute command
            return Invoke-Expression $cmnd
        }
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

        [string]$Pod,

        [string]$Service,

        [string]$Namespace,

        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    begin {
        # build command
        $cmnd = "kubectl $Verb $($Kind.ToLower())s"
        $PSBoundParameters.Remove('Verb') | Out-Null

        # build parameters
        $params = [System.Collections.Generic.List[string]]::new()
        if ($PSBoundParameters.Pod) {
            $params.Add($Pod)
            $PSBoundParameters.Remove('Pod') | Out-Null
        } elseif ($PSBoundParameters.Service) {
            $params.Add($Service)
            $PSBoundParameters.Remove('Service') | Out-Null
        }
        if ($PSBoundParameters.Namespace) {
            if ($Kind -ne 'Namespace') {
                $params.Add('--namespace')
            }
            $params.Add($Namespace)
            $PSBoundParameters.Remove('Namespace') | Out-Null
        }
        $PSBoundParameters.Remove('Kind') | Out-Null
        $PSBoundParameters.Xargs = $params.ToArray() + $Xargs
    }

    process {
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    }
}
