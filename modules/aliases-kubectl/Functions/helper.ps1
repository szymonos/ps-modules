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
    $LOCAL_BIN = [IO.Path]::Combine($HOME, '.local', 'bin')
    $KUBECTL = $IsWindows ? 'kubectl.exe' : 'kubectl'
    $KUBECTL_LOCAL = [IO.Path]::Combine($LOCAL_BIN, $KUBECTL)
    $KUBECTL_DIR = [IO.Path]::Combine($HOME, '.local', 'share', 'kubectl')

    $serverVersion = Get-KubectlServerVersion
    if (-not $serverVersion) {
        Write-Warning "Server not available."
        break
    }
    $kctlVer = [IO.Path]::Combine($KUBECTL_DIR, $serverVersion, $KUBECTL)

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
        Remove-Item $KUBECTL_LOCAL -Force -ErrorAction SilentlyContinue
        New-Item -ItemType SymbolicLink -Path $KUBECTL_LOCAL -Target $kctlVer | Out-Null
    }
}

<#
.SYNOPSIS
Change kubernetes context and sets the corresponding kubectl client version.
#>
function Set-KubectlUseContext {
    Write-Host "kubectl config use-context $args" -ForegroundColor Magenta
    kubectl config use-context @args
    Set-KubectlLocal
}
#endregion

#region aliases
Set-Alias -Name k -Value kubectl
Set-Alias -Name kv -Value Get-KubectlVersion
Set-Alias -Name kvc -Value Get-KubectlClientVersion
Set-Alias -Name kvs -Value Get-KubectlServerVersion
Set-Alias -Name kcuctx -Value Set-KubectlUseContext
#endregion
