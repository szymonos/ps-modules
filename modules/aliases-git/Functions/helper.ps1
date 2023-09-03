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
#endregion

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


#region helper git grep functions
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
