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

#region other
<#
.SYNOPSIS
Refresh all git repositories in subdirectories of the current folder.
#>
function grefresh {
    Push-Location
    # check if in git repo
    $isGitRepo = git rev-parse --is-inside-work-tree 2>$null && $true || $false
    if ($isGitRepo) {
        # get only the current dir
        $dirs = Get-Item .
    } else {
        # get all subdirectories
        $dirs = Get-ChildItem -Directory
    }
    foreach ($dir in $dirs) {
        Set-Location $dir
        # check if in git repo
        $hasRemote = (git remote 2>$null) ? $true : $false
        if ($hasRemote) {
            # perform refresh
            $follow = $dir -eq $dirs[0] ? '' : "`n"
            Write-Host "$follow$($dir.Name)" -ForegroundColor Cyan
            gsw && gpl && gbdm
        }
    }
    Pop-Location
}
#endregion
