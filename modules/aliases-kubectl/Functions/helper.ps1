#region helper functions
<#
.SYNOPSIS
Get kubectl client version.
#>
function Get-KubectlVersion {
    # get-full version
    $v = kubectl version -o=json 2>$null | ConvertFrom-Json
    # convert back to json selected properties
    $verJson = [ordered]@{
        clientVersion = [ordered]@{
            gitVersion = $v.clientVersion.gitVersion
            buildDate  = $v.clientVersion.buildDate
            goVersion  = $v.clientVersion.goVersion
            platform   = $v.clientVersion.platform
        }
        serverVersion = [ordered]@{
            gitVersion = $v.serverVersion.gitVersion -replace '(v[\d.]+).*', "`$1"
            buildDate  = $v.serverVersion.buildDate
            goVersion  = $v.serverVersion.goVersion
            platform   = $v.serverVersion.platform
        }
    } | ConvertTo-Json

    # format output command
    if (Get-Command yq -CommandType Application -ErrorAction SilentlyContinue) {
        $verJson | yq -p json -o yaml
    } elseif (Get-Command jq -CommandType Application -ErrorAction SilentlyContinue) {
        $verJson | jq
    } else {
        $verJson
    }
}


<#
.SYNOPSIS
Get kubectl client version.
#>
function Get-KubectlClientVersion {
    return (kubectl version -o=json 2>$null | ConvertFrom-Json).clientVersion.gitVersion
}


<#
.SYNOPSIS
Get kubernetes server version.
#>
function Get-KubectlServerVersion {
    return (kubectl version -o=json 2>$null | ConvertFrom-Json).serverVersion.gitVersion -replace '(v[\d.]+).*', "`$1"
}


<#
.SYNOPSIS
Set kubernetes current namespace context.
#>
function Set-KubectlContextCurrentNamespace {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace
    )

    begin {
        # get namespace name
        $namespace = if ($PsBoundParameters.Namespace) {
            $PsBoundParameters.Namespace
        } else {
            $prop = @(
                @{ Name = 'Name'; Expression = { $_.metadata.name } }
                @{ Name = 'Status'; Expression = { $_.status.phase } }
                @{ Name = 'CreatedAt'; Expression = { $_.metadata.creationTimestamp } }
            )
            kubectl get namespace --output json `
            | ConvertFrom-Json `
            | Select-Object -ExpandProperty items `
            | Select-Object -Property $prop `
            | Get-ArrayIndexMenu -Value -Message 'Select namespace to switch context to' `
            | Select-Object -ExpandProperty name
        }
    }

    process {
        # execute command
        Invoke-WriteExecCommand -Command 'kubectl config set-context --current --namespace' -Xargs $namespace
    }
}


<#
.SYNOPSIS
Decode and print kubernetes secret data
#>
function Get-KubectlSecretDecodedData {
    # convert secret to PSObject
    $secretJson = kubectl get secret @args -o json | ConvertFrom-Json
    # decode and write secret data
    $secretJson.data.PSobject.Properties | ForEach-Object {
        Write-Host "# $($_.Name)" -ForegroundColor DarkGreen
        [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_.Value)).Trim()
    }
}


<#
.SYNOPSIS
Change kubernetes context and sets the corresponding kubectl client version.
#>
function Set-KubectlContext {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgK8sGetContexts @args })]
        [string]$Context
    )

    begin {
        # get context name
        $ctx = if ($PSBoundParameters.Context) {
            $PSBoundParameters.Context
        } else {
            Get-KubectlContext -Output 'object' `
            | Select-Object name, cluster, namespace `
            | Get-ArrayIndexMenu -Value -Message 'Select kubernetes context to switch to.' `
            | Select-Object -ExpandProperty name
        }
    }

    process {
        # execute command
        Invoke-WriteExecCommand -Command 'kubectl config use-context' -Xargs $ctx
        # set kubectl binary to server version
        Set-KubectlLocal
    }
}


<#
.SYNOPSIS
Get list of available kubernetes contexts.
#>
function Remove-KubectlContext {
    $ctx = Get-KubectlContext -Output 'object' | Select-Object name, cluster, user | Get-ArrayIndexMenu -Value

    # unset context
    kubectl config unset "contexts.$($ctx.name)"
    kubectl config unset "clusters.$($ctx.cluster)"
    kubectl config unset "users.$($ctx.user)"
}


<#
.SYNOPSIS
Get list of available kubernetes contexts.
#>
function Get-KubectlContext {
    param (
        [ValidateNotNullOrEmpty()]
        [ValidateSet('json', 'object', 'table')]
        [string]$Output = 'table'
    )

    $config = kubectl config view --output json | ConvertFrom-Json
    $ctxs = foreach ($ctx in $config.contexts) {
        [PSCustomObject]@{
            '@'       = $ctx.name -eq $config.'current-context' ? '*' : $null
            name      = $ctx.name
            cluster   = $ctx.context.cluster
            namespace = $ctx.context.namespace
            user      = $ctx.context.user
        }
    }

    switch ($Output) {
        json {
            if (Get-Command jq -CommandType Application -ErrorAction SilentlyContinue) {
                $ctxs | ConvertTo-Json | jq
            } else {
                $ctxs | ConvertTo-Json
            }
        }
        object {
            $ctxs
        }
        table {
            $ctxs | Format-Table
        }
    }
}


<#
.SYNOPSIS
Downloads kubectl client version corresponding to kubernetes server version and creates symbolic link
to the client in $HOME/.local/bin directory.
.DESCRIPTION
Function requires the $HOME/.local/bin directory to be preceding path in $PATH environment variable.
#>
function Set-KubectlLocal {
    begin {
        # determine kubectl binary name
        $KUBECTL = $IsWindows ? 'kubectl.exe' : 'kubectl'
        # calculate paths
        $LOCAL_BIN = [IO.Path]::Combine($HOME, '.local', 'bin')
        $KUBECTL_LOCAL = [IO.Path]::Combine($LOCAL_BIN, $KUBECTL)
        $KUBECTL_DIR = [IO.Path]::Combine($HOME, '.local', 'share', 'kubectl')
        # initialize retry variable for kubectl download loop
        $RETRY_COUNT = 0
    }

    process {
        # check kubernetes server version
        $serverVersion = Get-KubectlServerVersion
        if (-not $serverVersion) {
            Write-Warning 'Server not available.'
            break
        }
        # calculate kubectl path corresponding to server version
        $kctlVer = [IO.Path]::Combine($KUBECTL_DIR, $serverVersion, $KUBECTL)

        # check if ~/.local/bin/kubectl symbolic link points to the above path
        if ((Get-ItemPropertyValue $KUBECTL_LOCAL -Name LinkTarget -ErrorAction SilentlyContinue) -ne $kctlVer) {
            if (-not (Test-Path $LOCAL_BIN)) {
                New-Item $LOCAL_BIN -ItemType Directory | Out-Null
            }
            if (-not (Test-Path $kctlVer -PathType Leaf)) {
                New-Item $([IO.Path]::Combine($KUBECTL_DIR, $serverVersion)) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
                $dlSysArch = if ($IsWindows) {
                    'windows/amd64'
                } elseif ($IsLinux) {
                    'linux/amd64'
                } elseif ($IsMacOS) {
                    'darwin/arm64'
                }
                do {
                    [Net.WebClient]::new().DownloadFile("https://dl.k8s.io/release/${serverVersion}/bin/$dlSysArch/$KUBECTL", $kctlVer)
                    $RETRY_COUNT++
                } until ((Test-Path $kctlVer -PathType Leaf) -or $RETRY_COUNT -ge 2)
                if (-not $IsWindows) {
                    chmod +x $kctlVer
                }
            }
            # replace existing ~/.local/bin/kubectl symbolic link
            New-Item -ItemType SymbolicLink -Path $KUBECTL_LOCAL -Target $kctlVer -Force | Out-Null
        }
    }

    clean {
        # remove symbolic link if target does not exist
        if (-not (Test-Path $kctlVer -PathType Leaf)) {
            Remove-Item $KUBECTL_LOCAL -Force
        }
    }
}


<#
.SYNOPSIS
Connect remotely to the specified pod on the cluster. By default sh shell is being executed.

.PARAMETER Pod
Name of the pod to connect to.
.PARAMETER Container
Explicitly specify the container in the pod to connect to.
.PARAMETER Namespace
Specify namespace of the pod.
.PARAMETER Command
Specify to run any specified command.
.PARAMETER bash
Specify to run bash shell.
.PARAMETER python
Specify to run python REPL.
.PARAMETER pwsh
Specify to run PowerShell shell.
#>
function Connect-KubernetesContainer {
    [CmdletBinding(DefaultParameterSetName = 'Shell')]
    param (
        [Alias('p')]
        [Parameter(Position = 0, Mandatory = $true)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

        [Alias('c')]
        [Parameter(Position = 1)]
        [ArgumentCompleter({ ArgK8sGetPodContainers @args })]
        [string]$Container,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace,

        [Alias('cmd')]
        [Parameter(ParameterSetName = 'Command')]
        [string]$Command,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$bash,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$python,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$pwsh
    )

    begin {
        # build kubectl command string
        $sb = [System.Text.StringBuilder]::new("kubectl exec --stdin --tty $($PSBoundParameters.Pod)")
        if ($PSBoundParameters.Namespace) {
            $sb.Append(" --namespace $($PSBoundParameters.Namespace)") | Out-Null
        }
        if ($PSBoundParameters.Container) {
            $sb.Append(" --container $($PSBoundParameters.Container)") | Out-Null
        }
        # specify command to be used in the container
        switch ($PsCmdlet.ParameterSetName) {
            Shell {
                if ($PSBoundParameters.bash) {
                    $sb.Append(' -- bash') | Out-Null
                } elseif ($PSBoundParameters.python) {
                    $sb.Append(' -- python') | Out-Null
                } elseif ($PSBoundParameters.PowerShell) {
                    $sb.Append(' -- pwsh') | Out-Null
                } else {
                    $sb.Append(' -- sh') | Out-Null
                }
            }
            Command {
                $sb.Append(" -- $Command") | Out-Null
            }
        }
        # get the command string
        $cmnd = $sb.ToString()
    }

    process {
        # execute command
        Invoke-WriteExecCommand -Command $cmnd
    }
}


<#
.SYNOPSIS
Debug cluster pods using interactive debugging containers.

.PARAMETER Pod
Name of the pod to be debugged.
.PARAMETER Namespace
Specify namespace of the pod.
.PARAMETER Command
Specify to run any specified command in the debug container.
.PARAMETER bash
Specify to run bash shell in the debug container.
.PARAMETER python
Specify to run python REPL in the debug container.
.PARAMETER pwsh
Specify to run PowerShell shell in the debug container.
#>
function Debug-KubernetesPod {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

        [Parameter(Position = 1)]
        [string]$Image,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace,

        [Alias('cmd')]
        [Parameter(ParameterSetName = 'Command')]
        [string]$Command,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$sh,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$bash,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$python,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$pwsh
    )

    begin {
        # build kubectl command string
        $sb = [System.Text.StringBuilder]::new("kubectl debug $($PSBoundParameters.Pod) --stdin --tty")
        if ($PSBoundParameters.Namespace) {
            $sb.Append(" --namespace $($PSBoundParameters.Namespace)") | Out-Null
        }
        $sb.Append(" --image=$($PSBoundParameters.Image)") | Out-Null
        # specify command to be used in the container
        switch ($PsCmdlet.ParameterSetName) {
            Shell {
                if ($PSBoundParameters.bash) {
                    $sb.Append(' -- bash') | Out-Null
                } elseif ($PSBoundParameters.python) {
                    $sb.Append(' -- python') | Out-Null
                } elseif ($PSBoundParameters.pwsh) {
                    $sb.Append(' -- pwsh') | Out-Null
                } elseif ($PSBoundParameters.sh) {
                    $sb.Append(' -- sh') | Out-Null
                }
            }
            Command {
                $sb.Append(" -- $Command") | Out-Null
            }
        }
        # get the command string
        $cmnd = $sb.ToString()
    }

    process {
        # execute command
        Invoke-WriteExecCommand -Command $cmnd
    }
}


<#
.SYNOPSIS
Get logs from the specified pod.

.PARAMETER Pod
Name of the pod to get logs from.
.PARAMETER Container
Specify container in the pod to get logs from.
.PARAMETER Namespace
Specify namespace of the pod.
#>
function Get-KubectlPodLogs {
    [CmdletBinding(DefaultParameterSetName = 'Shell')]
    param (
        [Alias('p')]
        [Parameter(Position = 0, Mandatory = $true)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

        [Alias('c')]
        [Parameter(Position = 1)]
        [ArgumentCompleter({ ArgK8sGetPodContainers @args })]
        [string]$Container,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace
    )

    begin {
        # build kubectl command string
        $sb = [System.Text.StringBuilder]::new("kubectl logs -f $($PSBoundParameters.Pod)")
        if ($PSBoundParameters.Namespace) {
            $sb.Append(" --namespace $($PSBoundParameters.Namespace)") | Out-Null
        }
        if ($PSBoundParameters.Container) {
            $sb.Append(" --container $($PSBoundParameters.Container)") | Out-Null
        }
        # get the command string
        $cmnd = $sb.ToString()
    }

    process {
        # execute command
        Invoke-WriteExecCommand -Command $cmnd
    }
}
#endregion


#region aliases
New-Alias -Name kv -Value Get-KubectlVersion
New-Alias -Name kvc -Value Get-KubectlClientVersion
New-Alias -Name kvs -Value Get-KubectlServerVersion
New-Alias -Name kcgctx -Value Get-KubectlContext
New-Alias -Name kcuctx -Value Set-KubectlContext
New-Alias -Name kc -Value Set-KubectlContext
New-Alias -Name kcrmctx -Value Remove-KubectlContext
New-Alias -Name kgsecd -Value Get-KubectlSecretDecodedData
New-Alias -Name kcsctxcns -Value Set-KubectlContextCurrentNamespace
New-Alias -Name kn -Value Set-KubectlContextCurrentNamespace
New-Alias -Name kex -Value Connect-KubernetesContainer
New-Alias -Name kdbg -Value Debug-KubernetesPod
New-Alias -Name klo -Value Get-KubectlPodLogs
#endregion
