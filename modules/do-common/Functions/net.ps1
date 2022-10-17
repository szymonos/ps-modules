<#
.SYNOPSIS
Function resolving CIDR notation range.
#>
function Convert-CidrToRange {
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
