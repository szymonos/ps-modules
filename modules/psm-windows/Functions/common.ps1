<#
.SYNOPSIS
Retry executing command if fails on HttpRequestException.
.PARAMETER Command
Script block of commands to execute.
.PARAMETER MaxRetries
Maximum number of retries to rerun the script block.
#>
function Invoke-CommandRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The command to be invoked.')]
        [scriptblock]$Command,

        [Parameter(HelpMessage = 'The number of retries the command should be invoked.')]
        [int]$MaxRetries = 10
    )

    Set-Variable -Name retryCount -Value 0
    do {
        try {
            Invoke-Command -ScriptBlock $Command
            $exit = $true
        } catch [System.IO.IOException] {
            if ($_.Exception.TargetSite.Name -eq 'MoveNext') {
                if ($_.ErrorDetails) {
                    Write-Verbose $_.ErrorDetails.Message
                } else {
                    Write-Verbose $_.Exception.Message
                }
                Write-Host "`nRetrying..."
            } else {
                Write-Verbose $_.Exception.GetType().FullName
                Write-Error $_
            }
        } catch [System.AggregateException] {
            if ($_.Exception.InnerException.GetType().Name -eq 'HttpRequestException') {
                Write-Verbose $_.Exception.InnerException.Message
                Write-Host "`nRetrying..."
            } else {
                Write-Verbose $_.Exception.InnerException.GetType().FullName
                Write-Error $_
            }
        } catch {
            Write-Verbose $_.Exception.GetType().FullName
            Write-Error $_
        }
        $retryCount++
        if ($retryCount -eq $MaxRetries) {
            $exit = $true
        }
    } until ($exit)
}

<#
.SYNOPSIS
Combines objects from the pipeline into a single string.

.PARAMETER InputObject
Specifies the text to be joined.
.PARAMETER Separator
Text or characters such as a comma or semicolon that's inserted between the text for each pipeline object.
.PARAMETER SingleQuote
Wraps the string value of each pipeline object in single quotes.
.PARAMETER DoubleQuote
Wraps the string value of each pipeline object in double-quotes.
#>
function Join-Str {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string[]]$InputObject,

        [string]$Separator = ' ',

        [Parameter(ParameterSetName = 'Single')]
        [switch]$SingleQuote,

        [Parameter(ParameterSetName = 'Double')]
        [switch]$DoubleQuote
    )

    begin {
        # instantiate list to store quoted elements
        $lst = [System.Collections.Generic.List[string]]::new()
        # calculate quote char
        $quote = if ($SingleQuote) {
            "'"
        } elseif ($DoubleQuote) {
            '"'
        } else {
            ''
        }
    }

    process {
        # quote input elements
        $lst.Add("${quote}$_${quote}")
    }

    end {
        # return joined elements
        return [string]::Join($Separator, $lst)
    }
}

<#
.SYNOPSIS
Check if PowerShell runs elevated.
#>
function Test-IsAdmin {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]$currentIdentity
    $admin = [System.Security.Principal.WindowsBuiltInRole]'Administrator'

    return $principal.IsInRole($admin)
}

<#
.SYNOPSIS
Refresh path environment variable for process scope.
#>
function Update-SessionEnvironmentPath {
    # instantiate a HashSet to store unique paths
    $auxHashSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    # get Path env variable from all scopes and build unique set
    foreach ($scope in @('Machine', 'User', 'Process')) {
        [Environment]::GetEnvironmentVariable('Path', $scope).Split(';').Where({ $_ }).ForEach({
                $auxHashSet.Add($_) | Out-Null
            }
        )
    }

    # build a path string from the HashSet
    $pathStr = [string]::Join([System.IO.Path]::PathSeparator, $auxHashSet)
    # set the Path environment variable in the current process scope
    [System.Environment]::SetEnvironmentVariable('Path', $pathStr, 'Process')
}

Set-Alias -Name refreshenvpath -Value Update-SessionEnvironmentPath
