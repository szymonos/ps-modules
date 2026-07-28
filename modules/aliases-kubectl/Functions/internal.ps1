<#
.SYNOPSIS
Download the kubectl binary for the specified server version, verify its integrity
and place it atomically at the destination path.
.DESCRIPTION
The binary is streamed to a temporary file with progress reporting and a request
timeout, then validated against the official SHA256 checksum published by the
kubernetes release server. Only a fully downloaded and verified file is moved to
the destination, so an interrupted or corrupted download never replaces a good
binary. Partial files are always cleaned up.

.PARAMETER Version
Kubernetes server version to download the matching kubectl client for (e.g. 'v1.35.6').
.PARAMETER SysArch
Download system architecture in '<os>/<arch>' format (e.g. 'linux/amd64').
.PARAMETER Destination
Full path the verified kubectl binary should be saved to.
.PARAMETER BinaryName
Name of the kubectl binary ('kubectl' or 'kubectl.exe').
#>
function Invoke-KubectlDownload {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Version,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SysArch,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [ValidateNotNullOrEmpty()]
        [string]$BinaryName = 'kubectl'
    )

    begin {
        $baseUri = "https://dl.k8s.io/release/$Version/bin/$SysArch/$BinaryName"
        # download to a temporary file so the destination is never left partial
        $tempFile = "$Destination.$([IO.Path]::GetRandomFileName()).part"
    }

    process {
        # get the expected checksum first, so a failure here aborts before downloading
        try {
            $expectedHash = (Invoke-RestMethod -Uri "$baseUri.sha256" -TimeoutSec 30).Trim()
        } catch {
            Write-Warning "Failed to retrieve kubectl checksum for $Version ($($_.Exception.Message))."
            return $false
        }

        $client = [Net.Http.HttpClient]::new()
        # bound the whole request so a stalled download cannot hang the terminal
        $client.Timeout = [timespan]::FromMinutes(5)
        try {
            $client.DefaultRequestHeaders.UserAgent.ParseAdd('PowerShell')
            $response = $client.GetAsync($baseUri, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            try {
                if (-not $response.IsSuccessStatusCode) {
                    Write-Warning "Failed to download kubectl $Version. Status code: $($response.StatusCode)."
                    return $false
                }

                $totalBytes = $response.Content.Headers.ContentLength
                $srcStream = $response.Content.ReadAsStreamAsync().Result
                $dstStream = [IO.FileStream]::new($tempFile, [IO.FileMode]::Create, [IO.FileAccess]::Write)
                try {
                    $buffer = [byte[]]::new(1MB)
                    $readTotal = 0
                    while (($read = $srcStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $dstStream.Write($buffer, 0, $read)
                        $readTotal += $read
                        if ($totalBytes) {
                            $percent = [math]::Round($readTotal / $totalBytes * 100)
                            $status = "$([math]::Round($readTotal / 1MB, 1))/$([math]::Round($totalBytes / 1MB, 1)) MB"
                            Write-Progress -Activity "Downloading kubectl $Version" -Status $status -PercentComplete $percent
                        } else {
                            Write-Progress -Activity "Downloading kubectl $Version" -Status "$([math]::Round($readTotal / 1MB, 1)) MB"
                        }
                    }
                } finally {
                    $dstStream.Dispose()
                    $srcStream.Dispose()
                    Write-Progress -Activity "Downloading kubectl $Version" -Completed
                }
            } finally {
                $response.Dispose()
            }
        } catch {
            Write-Warning "Failed to download kubectl $Version ($($_.Exception.InnerException.Message ?? $_.Exception.Message))."
            return $false
        } finally {
            $client.Dispose()
        }

        # verify integrity before accepting the file
        $actualHash = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash
        if ($actualHash -ne $expectedHash) {
            Write-Warning "Checksum mismatch for kubectl $Version - discarding download."
            return $false
        }

        # atomically move the verified binary into place
        [IO.File]::Move($tempFile, $Destination, $true)
        return $true
    }

    clean {
        # always remove the temporary file if it is still around
        if (Test-Path $tempFile -PathType Leaf) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}


<#
.SYNOPSIS
Write provided kubectl with its arguments and then execute it.
You can suppress writing the kubectl by providing -Quiet as one of the arguments.
You can suppress executing the kubectl by providing -WhatIf as one of the arguments.

.PARAMETER Command
kubectl command to be executed.
.PARAMETER Xargs
Additional arguments to be passed to the kubectl command.
.PARAMETER WhatIf
If specified, the command will not be executed, but only written to the console.
.PARAMETER Quiet
If specified, the command will not be printed to the console.
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
        Write-Debug "Invoke-WriteExecKubectl.Command`n`e[22m$Command`n"
        if ($PSBoundParameters.Xargs) {
            Write-Debug "Invoke-WriteExecKubectl.Xargs`n`e[22m$Xargs`n"
        }
        # execute command
        & kubectl @Command @Xargs
    }
}


<#
.SYNOPSIS
Build a kubectl command for specific kinds and o operations (verbs).
.DESCRIPTION
The command allows to create functions with autocompletion for specific kubectl operations.

.PARAMETER Verb
The kubectl operation to be performed. Valid values are 'get', 'describe', and 'delete'.
.PARAMETER Kind
The kind of kubernetes object to be operated on. Valid values are 'Pod', 'Service', 'Namespace', and 'Secret'.
.PARAMETER Name
The name of the resource to be operated on. Optional parameter.
.PARAMETER Namespace
The namespace in which the operation should be performed. Optional parameter.
.PARAMETER Xargs
Additional arguments to be passed to the kubectl command.
.PARAMETER WhatIf
If specified, the command will not be executed, but only written to the console.
.PARAMETER Quiet
If specified, the command will not be printed to the console.
#>
function Build-KubectlCommand {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Verb,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Kind,

        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [ValidateNotNullOrEmpty()]
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
        $cmnd.AddRange([string[]]@($PSBoundParameters.Verb.ToLower(), $PSBoundParameters.Kind.ToLower()))
        @('Verb', 'Kind').ForEach({ $PSBoundParameters.Remove($_) | Out-Null })

        # build parameters
        if ($PSBoundParameters.Resource) {
            $cmnd.Add($Resource)
            $PSBoundParameters.Remove('Resource') | Out-Null
        }

        if ($PSBoundParameters.Namespace) {
            if ($Kind -notin @('ns', 'namespace', 'namespaces')) {
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
