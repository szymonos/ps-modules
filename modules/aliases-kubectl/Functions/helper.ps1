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
Downloads kubectl client version corresponding to kubernetes server version and creates symbolic link
to the client in $HOME/.local/bin directory.
.DESCRIPTION
Function requires the $HOME/.local/bin directory to be preceding path in $PATH environment variable.
#>
function Set-KubectlLocal {
    # determine kubectl binary name
    $KUBECTL = $IsWindows ? 'kubectl.exe' : 'kubectl'
    # calculate paths
    $LOCAL_BIN = [IO.Path]::Combine($HOME, '.local', 'bin')
    $KUBECTL_LOCAL = [IO.Path]::Combine($LOCAL_BIN, $KUBECTL)
    $KUBECTL_DIR = [IO.Path]::Combine($HOME, '.local', 'share', 'kubectl')

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
            } until (Test-Path $kctlVer -PathType Leaf)
            if (-not $IsWindows) {
                chmod +x $kctlVer
            }
        }
        # replace existing ~/.local/bin/kubectl symbolic link
        Remove-Item $KUBECTL_LOCAL -Force -ErrorAction SilentlyContinue
        New-Item -ItemType SymbolicLink -Path $KUBECTL_LOCAL -Target $kctlVer | Out-Null
    }
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
Change kubernetes context and sets the corresponding kubectl client version.
#>
function Set-KubectlContext {
    Write-Host "kubectl config use-context $args" -ForegroundColor Magenta

    $contexts = Get-KubectlContext -Output 'object' | Sort-Object name
    if ($args -in $contexts.name) {
        kubectl config use-context @args
        Set-KubectlLocal
    } elseif (-not $args) {
        $ctx = $contexts `
        | Select-Object name, cluster, namespace `
        | Get-ArrayIndexMenu -Value -Message 'Select kubernetes context to switch to.'
        kubectl config use-context $ctx.name
        Set-KubectlLocal
    } else {
        Write-Warning "Context does not exist ($($args[0]))"
    }
}
#endregion

<#
.SYNOPSIS
Decode and print kubernetes secret data
#>
function Get-SecretDecodedData {
    # convert secret to PSObject
    $secretJson = kubectl get secret @args -o json | ConvertFrom-Json
    # decode and write secret data
    $secretJson.data.PSobject.Properties | ForEach-Object {
        Write-Host "# $($_.Name)" -ForegroundColor DarkGreen
        [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_.Value)).Trim()
    }
}

#region aliases
Set-Alias -Name k -Value kubectl
Set-Alias -Name kv -Value Get-KubectlVersion
Set-Alias -Name kvc -Value Get-KubectlClientVersion
Set-Alias -Name kvs -Value Get-KubectlServerVersion
Set-Alias -Name kcgctx -Value Get-KubectlContext
Set-Alias -Name kcuctx -Value Set-KubectlContext
Set-Alias -Name kcrmctx -Value Remove-KubectlContext
Set-Alias -Name kgsecd -Value Get-SecretDecodedData
#endregion
