#region helper git log functions
<#
.SYNOPSIS
Get-GitLogObject function aliases.
#>
function gglogs {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [int]$Count,

        [switch]$All,

        [string]$Grep
    )

    Get-GitLogObject @PSBoundParameters | Sort-Object DateUTC | Select-Object Commit, DateUTC, Subject, Author
}

function gglo {
    [CmdletBinding()]
    param ([int]$Count = 30)

    gglogs -Count $Count
}
function ggloa {
    [CmdletBinding()]
    param ([int]$Count = 30)

    gglogs -Count $Count -All
}
#endregion

#region helper git log colored functions
<#
.SYNOPSIS
Get-GitLogObject function colored aliases.
#>
function gglogc {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [int]$Count,

        [switch]$All,

        [string]$Grep
    )

    # build properties for Format-Table
    $prop = @(
        @{ Name = 'Commit'; Expression = { "`e[33m$($_.Commit)`e[0m" } }
        @{ Name = 'DateUTC'; Expression = { "`e[32m$($_.DateUTC)`e[0m" } }
        @{ Name = 'Reference'; Expression = { $ref = $_.Reference.Replace('origin/', '').Split(',')[0]; "`e[31m$($ref.Substring(0, [Math]::Min(25, $ref.Length)))`e[0m" } }
        @{ Name = 'Subject'; Expression = { $_.Subject.Substring(0, [Math]::Min(49, $_.Subject.Length)) } }
        @{ Name = 'Author'; Expression = { "`e[34;1m$($_.Author)`e[0m" } }
        @{ Name = 'Email'; Expression = { "`e[36;3m$($_.Email)`e[0m" } }
    )
    Get-GitLogObject @PSBoundParameters | Sort-Object DateUTC | Format-Table -Property $prop
}

function ggloc {
    [CmdletBinding()]
    param ([int]$Count = 30)

    gglogc -Count $Count
}

function ggloca {
    [CmdletBinding()]
    param ([int]$Count = 30)

    gglogc -Count $Count -All
}
#endregion

#region helper git grep functions
function ggrep {
    [CmdletBinding()]
    param ([string]$Grep)

    gglogs -Grep $Grep
}

function ggrepa {
    [CmdletBinding()]
    param ([string]$Grep)

    gglogs -Grep $Grep -All
}

function ggrepc {
    [CmdletBinding()]
    param ([string]$Grep)

    gglogc -Grep $Grep
}

function ggrepca {
    [CmdletBinding()]
    param ([string]$Grep)

    gglogc -Grep $Grep -All
}
#endregion

#region helper git remove branches
function gbdl {
    Remove-GitLocalBranches
}

function gbdl! {
    Remove-GitLocalBranches -DeleteNoMerged
}

function gbdm {
    Remove-GitMergedBranches
}

function gbdm! {
    Remove-GitMergedBranches -DeleteRemote
}
#endregion

#region helper grun functions
<#
.DESCRIPTION
Alias functions using the Invoke-GitRepoCommand internal function that runs specified git commands in the current repo,
or all repos located in subdirectories of the current folder.
Function runs only in repositories with remote set.
#>

<#
.SYNOPSIS
Invoke-GitRepoCommand alias function.

.PARAMETER cmd
Script block of commands to execute.
#>
function grunrepocmd ([scriptblock]$cmd) {
    Invoke-GitRepoCommand -Command $cmd
}

<#
.SYNOPSIS
Refresh all git repositories in subdirectories of the current folder.
#>
function grunrefresh {
    $cmd = {
        gsw && gfa! && gmg && gbdm
    }
    Invoke-GitRepoCommand -Command $cmd
}

<#
.SYNOPSIS
Set git local settings in all git repositories.

.PARAMETER Option
Git local setting option.
.PARAMETER Value
Git local setting value.
#>
function gruncfl {
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Option,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )

    $cmd = {
        git config --local $Option $Value
        Write-Host "${Option}: $(git config --local $Option)"
    }
    Invoke-GitRepoCommand -Command $cmd
}
#endregion
