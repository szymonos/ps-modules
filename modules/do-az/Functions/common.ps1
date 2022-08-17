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
Get index(es) or a value in provided array from selection menu.
.PARAMETER Array
Array of strings to get the selection menu.
.PARAMETER Message
Optional menu header to display.
.PARAMETER Value
Flag to return value(s) instead of index(es).
.PARAMETER List
Flag to choose from selection list instead of single value.
#>
function Get-ArrayIndexMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]$Array,

        [string]$Message,

        [switch]$Value,

        [switch]$List
    )

    begin {
        # convert objects in array to strings
        if ($Array[0].GetType().FullName -ne 'System.String') {
            $Array = $Array | Format-Table -AutoSize -HideTableHeaders | Out-String -Stream | Where-Object { $_ }
        }
        # create selection message
        $menu = for ($i = 0; $i -lt $Array.Count; $i++) {
            [PSCustomObject]@{ I = "[$i]"; H = '-'; Value = $Array[$i] }
        }
        $selMsg = $menu | Format-Table -Property @{ Name = 'I'; Expression = { $_.I }; Alignment = 'right'}, H, Value -AutoSize -HideTableHeaders | Out-String

        # create prompt message
        if (-not $Message) {
            $Message = $List ? 'Enter comma/space separated selection list' : 'Enter selection'
        }
        $msg = "`n`e[4m$Message`e[0m:`n$selMsg"
    }

    process {
        do {
            # read input
            $inputArray = (Read-Host -Prompt $msg).Split([char[]]@(' ', ','), [StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Unique
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
