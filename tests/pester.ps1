#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Run Pester tests for all modules or specified modules.

.PARAMETER Modules
Array of module names to run tests for. If not provided, all modules will be tested.

.EXAMPLE
# :run tests for all modules
tests/pester.ps1
# :run tests for the specified modules
$Modules = @('do-common', 'do-azure')
tests/pester.ps1 $Modules
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string[]]$Modules
)

begin {
    $ErrorActionPreference = 'Stop'

    # get all module directories
    $moduleDirs = if ($Modules) {
        Get-ChildItem -Path 'modules' -Directory | Where-Object { $_.Name -match ([string]::Join('|', $Modules)) }
    } else {
        Get-ChildItem -Path 'modules' -Filter 'tests' -Directory -Recurse
    }
    # check if any modules found
    if (-not $moduleDirs) {
        Write-Error 'No modules found'
        exit 1
    }
}

process {
    foreach ($module in $moduleDirs) {
        # $Module = $Modules[0]
        Invoke-Pester -Path $module -Output Detailed
    }
}
