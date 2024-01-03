<#
.SYNOPSIS
Parse winget upgrade results and return object with list of upgradeable packages.
.PARAMETER Operation
Specify if the result should return all installed packages or upgradeable only.
.EXAMPLE
Get-WingetResult
.EXAMPLE
Get-WingetResult -o 'upgrade'
#>
function Get-WingetResult {
    [CmdletBinding()]
    param (
        [Alias('o')]
        [Parameter(Position = 0)]
        [ValidateSet('list', 'upgrade')]
        [string]$Operation = 'list'
    )

    begin {
        switch ($Operation) {
            list {
                [string[]]$result = @(winget list).Where({ $_ -match '^\w' })
            }
            upgrade {
                [string[]]$result = @(winget upgrade).Where({ $_ -match '^\w' -and $_ -notmatch '(^\d+ +upgrades)|(--include-unknown)|(^No installed)' })
                # check for secondary explicit targeting for upgrade
                $targetIdx = [array]::IndexOf($result, ($result | Select-String 'explicit targeting' -Raw)) - 1
                if ($targetIdx -gt 0) {
                    $result = $result[0..$targetIdx]
                } else {
                    $result = @()
                }
            }
        }
    }

    process {
        # return if winget hasn't returned upgradeable packages
        try {
            if (-not $result[0].StartsWith('Name')) {
                return $result[0]
            }
        } catch {
            return
        }

        # index columns
        $idIndex = $result[0].IndexOf('Id')
        $versionIndex = $result[0].IndexOf('Version')
        $availableIndex = $result[0].IndexOf('Available')
        $sourceIndex = $result[0].IndexOf('Source')
        # Now cycle in real package and split accordingly
        $packages = [Collections.Generic.List[PSObject]]::new()
        for ($i = 1; $i -lt $result.Length; $i++) {
            $package = @{
                Name   = $result[$i].Substring(0, $idIndex).TrimEnd()
                Id     = $result[$i].Substring($idIndex, $versionIndex - $idIndex).TrimEnd()
                Source = $result[$i].Substring($sourceIndex, $result[$i].Length - $sourceIndex)
            }

            switch ($Operation) {
                list {
                    $package['Version'] = $result[$i].Substring($versionIndex, $sourceIndex - $versionIndex).TrimEnd()
                }
                upgrade {
                    $package['Version'] = $result[$i].Substring($versionIndex, $availableIndex - $versionIndex).TrimEnd()
                    $package['Available'] = $result[$i].Substring($availableIndex, $sourceIndex - $availableIndex).TrimEnd()
                }
            }
            $packages.Add([PSCustomObject]$package)
        }
    }

    end {
        switch ($Operation) {
            list {
                return $packages | Sort-Object -Property Name | Select-Object Name, Id, Version, Source
            }
            upgrade {
                return $packages
            }
        }
    }
}


<#
.SYNOPSIS
Update all packages that were not excluded or unknown.
.PARAMETER ExcludedItems
List of excluded packages from upgrade.
.EXAMPLE
Invoke-WingetUpgrade
.EXAMPLE
Invoke-WingetUpgrade -e @('Microsoft.Edge', 'Mozilla.Firefox')
#>
function Invoke-WingetUpgrade {
    [CmdletBinding()]
    param (
        [Alias('e')]
        [string[]]$ExcludedItems = @()
    )

    begin {
        if ([System.Environment]::OSVersion.Platform -ne 'Win32NT') {
            Write-Warning 'Function can be executed on Windows only!'
            break
        }
    }

    process {
        $packages = (Get-WingetResult -o 'upgrade') | Where-Object {
            $_.Id -notin $ExcludedItems
        }
        foreach ($item in $packages) {
            Write-Host $item.Name -ForegroundColor Magenta
            winget.exe upgrade --id $item.Id
        }
    }
}
