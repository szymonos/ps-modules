$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Retry executing command if fails on HttpRequestException.
.PARAMETER Script
Script block of commands to execute.
#>
function Invoke-CommandRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [scriptblock]$Script
    )
    do {
        try {
            Invoke-Command -ScriptBlock $Script
            $exit = $true
        } catch [System.Net.Http.HttpRequestException] {
            if ($_.ErrorDetails) {
                Write-Verbose $_.ErrorDetails.Message
            } else {
                Write-Verbose $_.Exception.Message
            }
            Write-Host 'Retrying...'
        } catch [System.AggregateException] {
            if ($_.Exception.InnerException.GetType().Name -eq 'HttpRequestException') {
                Write-Verbose $_.Exception.InnerException.Message
                Write-Host 'Retrying...'
            } else {
                Write-Verbose $_.Exception.InnerException.GetType().FullName
                Write-Error $_
            }
        } catch {
            Write-Verbose $_.Exception.GetType().FullName
            Write-Error $_
        }
    } until ($exit)
}

<#
.SYNOPSIS
Get index of a value in provided array from selection menu.
.PARAMETER Array
Array of strings to get the selection menu.
.PARAMETER Message
Optional menu header to display.
.PARAMETER Output
Choose between returning value or index of the array selection.
#>
function Get-ArrayIndexMenu {
    [CmdletBinding()]
    param (
        [Alias('a')]
        [Parameter(Mandatory)]
        [string[]]$Array,

        [Alias('m')]
        [string]$Message,

        [Alias('v')]
        [switch]$Value,

        [Alias('l')]
        [switch]$List
    )

    begin {
        # get array length for indentation calculation
        $arrayLen = "$($Array.Count)".Length
        # create selection menu
        $msg = (
            , "`n`e[4m$($Message ? $Message : 'Select option')`e[0m:`n" +
            $Array.ForEach({
                    $index = [array]::IndexOf($Array, $_)
                    $indent = ' ' * ($arrayLen - "$index".Length + 1)
                    "$indent[$index] - $_"
                }) + ''
        ) -join "`n"
    }

    process {
        do {
            # read input
            $inp = (Read-Host -Prompt $msg) -replace (',+', ',')
            # convert input to array
            $inputArray = Invoke-Expression "Write-Output $inp | Select-Object -Unique"
            $loop = if (-not $List -and $inputArray.Count -gt 1) {
                # check if list is expected
                Write-Output $true
            } else {
                # check if input contains valid numbers
                foreach ($i in $inputArray) {
                    if ($i -notin 0..($Array.Count - 1)) {
                        Write-Output $true
                        continue
                    }
                }
            }
        } while ($loop)
    }

    end {
        return $Value ? $inputArray.ForEach{ $Array[$_] } : $inputArray
    }
}
