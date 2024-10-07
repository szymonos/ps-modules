<#
.SYNOPSIS
Function to set the log file and return the path.

.PARAMETER Path
The path to the log file.
.PARAMETER Append
Switch, whether to append to the existing log file.
#>
function Set-LogFile {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Path = "logs/$(Get-Date -Format 'yyyyMMddHHmmss').log",

        [switch]$Append
    )

    # *ensure that the log file exists
    if ((Split-Path $Path -Leaf) -notmatch '\S+\.\S+$') {
        # generate log file name if it's not provided
        $Path = [System.IO.Path]::Combine($Path, "$(Get-Date -Format 'yyyyMMddTHHmmss').log")
    }
    if (-not (Test-Path $Path -PathType Leaf)) {
        # create the log file if it doesn't exist
        New-Item -Path $Path -ItemType File -Force | Out-Null
    } elseif (-not $Append) {
        # clean the existing logfile if it exists
        Set-Content -Path $Path -Value $null
    }

    # return PowerShell provider path
    return Convert-Path $Path
}


<#
.SYNOPSIS
Function to get the log context from the caller.

.PARAMETER Caller
The caller function stack frame.
.PARAMETER ErrorStackTrace
The error stack trace.
#>
function Get-LogContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [System.Management.Automation.CallStackFrame]$Caller,

        [ValidateScript({ $_ -match '\sline\s(\d+)' })]
        [string]$ErrorStackTrace
    )

    begin {
        # get the function call timestamp
        $ts = Get-Date
    }

    process {
        # get the caller function name
        $callerFunction = $Caller.FunctionName -like '<ScriptBlock>*' ? $Caller.FunctionName : "$($Caller.FunctionName)()"
        # get the caller script name
        $callerScript = $Caller.ScriptName ? (Split-Path -Path $Caller.ScriptName -Leaf) : $Caller.Location
        # get the invocation and function line numbers
        if ($ErrorStackTrace) {
            # get the line numbers from the error stack trace
            $stackSplit = $ErrorStackTrace.Split("`n")
            if ($callerFunction -like '<ScriptBlock>*') {
                $invocationLine = $stackSplit `
                    -match '\sline\s(\d+)' `
                    -replace '.*\sline\s(\d+).*', '$1' `
                | Select-Object -First 1
            } else {
                $funcLine = $stackSplit `
                    -match "$callerFunction,.*:\sline\s(\d+)" `
                    -replace '.*\sline\s(\d+).*', '$1'`
                | Select-Object -First 1
                $invocationLine = $stackSplit `
                    -notmatch "$callerFunction" `
                    -match '\sline\s(\d+)' `
                    -replace '.*\sline\s(\d+).*', '$1' `
                | Select-Object -First 1
            }
        } else {
            # get the line numbers from the caller
            if ($callerFunction -like '<ScriptBlock>*') {
                $invocationLine = $caller.ScriptLineNumber
            } else {
                $funcLine = $caller.ScriptLineNumber
                $invocationLine = $caller.InvocationInfo.ScriptLineNumber
            }
        }
    }

    end {
        # return the log context
        return [PSCustomObject]@{
            TimeStamp  = $ts
            Invocation = "${callerScript}:${invocationLine}"
            Function   = "${callerFunction}$($funcLine ? ":$funcLine" : '')"
            IsVerbose  = $Caller.InvocationInfo.BoundParameters.Verbose.IsPresent
            IsDebug    = $Caller.InvocationInfo.BoundParameters.Debug.IsPresent
        }
    }
}

<#
.SYNOPSIS
Functions to log messages to the console.

.PARAMETER Message
The message to log.
.PARAMETER Level
The level of the log message.
.PARAMETER ErrorStackTrace
The error stack trace.
#>
function Show-LogContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'ERROR', 'WARNING', 'VERBOSE', 'DEBUG')]
        [string]$Level = 'INFO',

        [ValidateScript({ $Level -eq 'ERROR' }, ErrorMessage = 'ErrorStackTrace is allowed for ERROR messages only.')]
        [string]$ErrorStackTrace
    )

    begin {
        # *capitalize the Type
        $Level = $Level.ToUpper()

        # *get the function caller context
        $callerParam = @{
            Caller = (Get-PSCallStack)[1]
        }
        if ($PSBoundParameters.ErrorStackTrace -match '\sline\s(\d+)') {
            $callerParam.ErrorStackTrace = $PSBoundParameters.ErrorStackTrace
        }
        $ctx = Get-LogContext @callerParam

        # *determine Debug/Verbose preference
        $isVerbose = $ctx.isVerbose -or $VerbosePreference -ge 'Continue'
        $isDebug = $ctx.isDebug -or $DebugPreference -ge 'Continue'
        # calculate if the message should be logged
        $shouldLog = if (($Level -eq 'VERBOSE' -and -not $isVerbose) -or ($Level -eq 'DEBUG' -and -not $isDebug)) {
            $false
        } else {
            $true
        }
    }

    process {
        if (-not $shouldLog) {
            return
        }

        # format log level
        $lvlColor = switch ($Level) {
            'INFO' { "`e[94m" }
            'ERROR' { "`e[91m" }
            'WARNING' { "`e[93m" }
            'VERBOSE' { "`e[96m" }
            'DEBUG' { "`e[35m" }
        }

        # build the log line
        $logLine = [string]::Join('|',
            "`e[32m$($ctx.TimeStamp.ToString('yyyy-MM-dd HH:mm:ss'))`e[0m",
            "${lvlColor}${Level}`e[0m",
            "`e[90m$($ctx.Invocation)`e[0m",
            "`e[90m$($ctx.Function)`e[0m: $Message"
        )
    }

    end {
        if ($shouldLog) {
            Write-Host $logLine
        }
    }
}


<#
.SYNOPSIS
Function to log messages to a log file.

.PARAMETER Path
The path to the log file.
.PARAMETER Message
The message to log.
.PARAMETER Level
The level of the log message.
.PARAMETER ErrorStackTrace
The error stack trace.
#>
function Write-LogContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'ERROR', 'WARNING', 'VERBOSE', 'DEBUG')]
        [string]$Level = 'INFO',

        [ValidateScript({ $Level -eq 'ERROR' }, ErrorMessage = 'ErrorStackTrace is allowed for ERROR messages only.')]
        [string]$ErrorStackTrace
    )

    begin {
        # *capitalize the Type
        $Level = $Level.ToUpper()

        # *get the function caller context
        $callerParam = @{
            Caller = (Get-PSCallStack)[1]
        }
        if ($PSBoundParameters.ErrorStackTrace -match '\sline\s(\d+)') {
            $callerParam.ErrorStackTrace = $PSBoundParameters.ErrorStackTrace
        }
        $ctx = Get-LogContext @callerParam
    }

    process {
        # build the log line
        [string[]]$logLine = [string]::Join('|',
            $ctx.TimeStamp.ToString('yyyy-MM-dd HH:mm:ss.fff'),
            $Level,
            $ctx.Invocation,
            $ctx.Function,
            $Message
        )
    }

    end {
        # write the log line to the log file
        [System.IO.File]::AppendAllLines($Path, $logLine)
    }
}
