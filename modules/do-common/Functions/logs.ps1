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
Functions to log messages to the console.

.PARAMETER Message
The message to log.
.PARAMETER Type
The type of the log message.
#>
function Show-LogContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'ERROR', 'WARNING', 'VERBOSE', 'DEBUG')]
        [string]$Level = 'INFO'
    )

    begin {
        # *capitalize the Type
        $Level = $Level.ToUpper()
        # *get the caller context outside of the function
        $caller = (Get-PSCallStack)[1]
        # get the caller function name
        $callerFunction = $caller.FunctionName
        # get the caller script name
        $callerScript = $caller.ScriptName ? (Split-Path -Path $caller.ScriptName -Leaf) : $caller.Location
        # get the caller line number
        $callerLine = $caller.ScriptLineNumber
    }

    process {
        # get the function call timestamp
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

        # format message based on the Type
        $Message = switch ($Level) {
            'INFO' {
                "`e[94m$Message`e[0m"
            }
            'ERROR' {
                "`e[91m$Message`e[0m"
            }
            'WARNING' {
                "`e[93m$Message`e[0m"
            }
            'VERBOSE' {
                "`e[96m$Message`e[0m"
            }
            'DEBUG' {
                "`e[35m$Message`e[0m"
            }
        }

        # build the caller context and message
        $callerMsg = [string]::Join('',
            $callerScript ? "${callerScript}:${callerLine}|" : '',
            $callerFunction ? "${callerFunction}" : '',
            ": $Message"
        )

        # build the log line
        $logLine = [string]::Join('|',
            "`e[32m$ts`e[0m",
            "`e[90m$Level`e[0m",
            $callerMsg
        )
    }

    end {
        Write-Host $logLine
    }
}


<#
.SYNOPSIS
Function to log messages to a log file.

.PARAMETER Message
The message to log.
.PARAMETER Type
The type of the log message.
.PARAMETER Path
The path to the log file.
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
        [string]$Level = 'INFO'
    )

    begin {
        # *get the function call timestamp
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'

        # *get the caller context outside of the function
        $caller = (Get-PSCallStack)[1]
        # get the caller function name
        $callerFunction = $caller.FunctionName
        # get the caller script name
        $callerScript = $caller.ScriptName ? (Split-Path -Path $caller.ScriptName -Leaf) : $caller.Location
        # get the caller line number
        $callerLine = $caller.ScriptLineNumber

        # *capitalize the Type
        $Level = $Level.ToUpper()
    }

    process {
        # build the caller context and message
        $callerMsg = [string]::Join('',
            $callerScript ? "${callerScript}:${callerLine}|" : '',
            $callerFunction ? "${callerFunction}" : '',
            ": $Message"
        )

        # build the log line
        [string[]]$logLine = [string]::Join('|',
            "$ts",
            "$Level",
            $callerMsg
        )
    }

    end {
        # write the log line to the log file
        [System.IO.File]::AppendAllLines($Path, $logLine)
    }
}
