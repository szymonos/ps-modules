#region helper git branch delete functions
function gbd {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [switch]$WhatIf,

        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git branch --delete $Branch"
    if (-not $PSBoundParameters.Quiet) {
        # write command to be executed
        Write-Host $cmnd -ForegroundColor Magenta
    }
    if (-not $PSBoundParameters.WhatIf) {
        # execute command
        Invoke-Expression $cmnd
    }
}
function gbd! {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [switch]$WhatIf,

        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git branch -D $Branch"
    # write command to be executed
    if (-not $PSBoundParameters.Quiet) {
        Write-Host $cmnd -ForegroundColor Magenta
    }
    # execute command
    if (-not $PSBoundParameters.WhatIf) {
        Invoke-Expression $cmnd
    }
}
function gbdo {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [switch]$WhatIf,

        [switch]$Quiet
    )

    # calculate command strings
    $commands = [System.Collections.Generic.List[string]]::new([string[]]"git branch --delete $Branch")
    if ($remote = git remote) {
        $commands.Add("git push --delete $remote $Branch")
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }

    # run commands
    foreach ($cmnd in $commands) {
        if (-not $PSBoundParameters.Quiet) {
            # write command to be executed
            Write-Host $cmnd -ForegroundColor Magenta
        }
        if (-not $PSBoundParameters.WhatIf) {
            # execute command
            Invoke-Expression $cmnd
        }
    }
}
function gbdo! {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [switch]$WhatIf,

        [switch]$Quiet
    )

    # calculate command strings
    $commands = [System.Collections.Generic.List[string]]::new([string[]]"git branch -D $Branch")
    if ($remote = git remote) {
        $commands.Add("git push --delete $remote $Branch")
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }

    # run commands
    foreach ($cmnd in $commands) {
        if (-not $PSBoundParameters.Quiet) {
            # write command to be executed
            Write-Host $cmnd -ForegroundColor Magenta
        }
        if (-not $PSBoundParameters.WhatIf) {
            # execute command
            Invoke-Expression $cmnd
        }
    }
}
function gpushd {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [switch]$WhatIf,

        [switch]$Quiet
    )

    # calculate command string
    if ($remote = git remote) {
        $cmnd = "git push --delete $remote $Branch"
        if (-not $PSBoundParameters.Quiet) {
            # write command to be executed
            Write-Host $cmnd -ForegroundColor Magenta
        }
        if (-not $PSBoundParameters.WhatIf) {
            # execute command
            Invoke-Expression $cmnd
        }
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
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
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [int]$Count,

        [Parameter(ParameterSetName = 'Commits')]
        [switch]$All,

        [Parameter(ParameterSetName = 'Tags')]
        [switch]$Tags,

        [string]$Grep
    )

    # build properties for Format-Table
    $refCmd = {
        $refs = switch -Regex ($_.Ref.Split(',').Trim().Where({ $_ -ne 'origin/HEAD' })) {
            '^tag:' { "`e[1;93m$($_ -replace '^tag: ')`e[0m" }
            '^origin/' { "`e[1;91m$_`e[0m" }
            '^HEAD' { "`e[1;96mHEAD -> `e[92m$($_ -replace 'HEAD -> ')`e[0m" }
            Default { "`e[1;92m$_`e[0m" }
        }
        $([string]::Join(', ', $refs))
    }
    $prop = @(
        @{ Name = 'Commit'; Expression = { "`e[33m$($_.Commit)`e[0m" } }
        @{ Name = 'DateUTC'; Expression = { "`e[32m$($_.DateUTC)`e[0m" } }
        @{ Name = 'Subject'; Expression = { $_.Subject.Substring(0, [Math]::Min(59, $_.Subject.Length)) } }
        @{ Name = 'Author'; Expression = { "`e[94;1m$($_.Author)`e[0m" } }
        @{ Name = 'Email'; Expression = { "`e[34;3m$($_.Email -match 'users.noreply.github.com' ? 'noreply@github.com' : $_.Email)`e[0m" } }
        @{ Name = 'Ref'; Expression = $refCmd }
    )
    Get-GitLogObject @PSBoundParameters | Sort-Object DateUTC | Format-Table -Property $prop -Wrap
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


function gglot {
    [CmdletBinding()]
    param ([int]$Count = 0)

    gglogc -Count $Count -Tags
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


#region helper switch function
function gsw {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [switch]$WhatIf,

        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git switch $(Get-GitResolvedBranch $Branch)"

    if (-not $PSBoundParameters.Quiet) {
        # write command to be executed
        Write-Host $cmnd -ForegroundColor Magenta
    }
    if (-not $PSBoundParameters.WhatIf) {
        # execute command
        Invoke-Expression $cmnd
    }
}
function gsw! {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [switch]$WhatIf,

        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git switch $(Get-GitResolvedBranch $Branch) --force"

    if (-not $PSBoundParameters.Quiet) {
        # write command to be executed
        Write-Host $cmnd -ForegroundColor Magenta
    }
    if (-not $PSBoundParameters.WhatIf) {
        # execute command
        Invoke-Expression $cmnd
    }
}
#endregion
