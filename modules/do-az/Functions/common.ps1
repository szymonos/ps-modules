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
    [CmdletBinding(DefaultParameterSetName = 'idx')]
    [OutputType([int], ParameterSetName = 'idx')]
    [OutputType([string], ParameterSetName = 'val')]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'idx')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'val')]
        [object[]]$Array,

        [Parameter(Position = 1)]
        [string]$Message,

        [Parameter(Mandatory, ParameterSetName = 'val')]
        [switch]$Value,

        [Parameter(ParameterSetName = 'idx')]
        [Parameter(ParameterSetName = 'val')]
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
        } while ($inputArray.ForEach({ $_ -in 0..($Array.Count - 1) }) -contains $false)
    }

    end {
        return $Value ? $inputArray.ForEach{ $Array[$_] } : $inputArray
    }
}

<#
.SYNOPSIS
Function resolving CIDR notation range.
#>
function ConvertFrom-CIDR {
    [CmdletBinding()]
    [OutputType([Collections.Generic.List[PSCustomObject]])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string[]]${InputObject}
    )

    begin {
        $ranges = [Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        $addr, $maskLength = $InputObject -split '/'
        [int]$maskLen = 0
        if (-not [int32]::TryParse($maskLength, [ref] $maskLen)) {
            throw "Cannot parse CIDR mask length string: '$maskLen'"
        }
        if (0 -gt $maskLen -or $maskLen -gt 32) {
            throw 'CIDR mask length must be between 0 and 32'
        }
        $ipAddr = [Net.IPAddress]::Parse($addr)
        if ($ipAddr -eq $null) {
            throw "Cannot parse IP address: $addr"
        }
        if ($ipAddr.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
            throw 'Can only process CIDR for IPv4'
        }

        $shiftCnt = 32 - $maskLen
        $mask = -bnot ((1 -shl $shiftCnt) - 1)
        $ipNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($ipAddr.GetAddressBytes(), 0))
        $ipStart = ($ipNum -band $mask)
        $ipEnd = ($ipNum -bor (-bnot $mask))

        # return as tuple of strings:
        $ranges.Add([PSCustomObject]@{
                CidrRange  = $InputObject[0]
                StartIP    = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipStart)) -join '.'
                EndIP      = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd)) -join '.'
                TotalHosts = $ipEnd - $ipStart + 1
            }
        )
    }

    end {
        return $ranges
    }
}
