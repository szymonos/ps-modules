#region helper git branch delete functions
function gbd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git branch --delete $Branch"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gbd! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git branch -D $Branch"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gbdo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command strings
    if ($remote = @(git remote)[0]) {
        $commands = [System.Collections.Generic.List[string]]::new()
        $commands.Add("git branch --delete $Branch")
        $commands.Add("git push --delete $remote $Branch")
        $PSBoundParameters.Remove('Branch') | Out-Null
    } else {
        Write-Host 'fatal: Remote repository not set.'
        return
    }

    # run commands
    foreach ($cmnd in $commands) {
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    }
}
function gbdo! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command strings
    if ($remote = @(git remote)[0]) {
        $commands = [System.Collections.Generic.List[string]]::new()
        $commands.Add("git branch -D $Branch")
        $commands.Add("git push --delete $remote $Branch")
        $PSBoundParameters.Remove('Branch') | Out-Null
    } else {
        Write-Host 'fatal: Remote repository not set.'
        return
    }

    # run commands
    foreach ($cmnd in $commands) {
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    }
}
function gbdl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )
    Remove-GitLocalBranches @PSBoundParameters
}
function gbdl! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )
    Remove-GitLocalBranches -DeleteNoMerged @PSBoundParameters
}
function gbdm {
    Remove-GitMergedBranches
}
function gbdm! {
    Remove-GitMergedBranches -DeleteRemote
}
function gpushd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        # calculate command string
        $cmnd = "git push --delete $remote $Branch"
        $PSBoundParameters.Remove('Branch') | Out-Null
        # run command
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
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


#region helper merge/rebase functions
function gmg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $rmt, $br = $Branch.Split('/', 2)
    $resolvedBranch = if ($rmt -in (git remote)) {
        "${rmt}/$(Get-GitResolvedBranch $br)"
    } else {
        Get-GitResolvedBranch $Branch
    }
    $cmnd = "git merge $resolvedBranch"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gmgo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command strings
    if ($remote = @(git remote)[0]) {
        # get current branch
        $currentBranch = git branch --show-current
        # resolve provided branch
        $resolvedBranch = Get-GitResolvedBranch $Branch
        $PSBoundParameters.Remove('Branch') | Out-Null
        # build list of commands to execute
        $commands = [System.Collections.Generic.List[string]]::new()
        $commands.Add("git fetch $remote --prune")
        if ($currentBranch -ne $resolvedBranch) {
            $commands.Add("git merge ${remote}/${currentBranch} --quiet")
        }
        $commands.Add("git merge ${remote}/${resolvedBranch}")
    } else {
        Write-Host 'fatal: Remote repository not set.'
        return
    }

    # run commands
    foreach ($cmnd in $commands) {
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    }
}
function grb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $rmt, $br = $Branch.Split('/', 2)
    $resolvedBranch = if ($rmt -in (git remote)) {
        "${rmt}/$(Get-GitResolvedBranch $br)"
    } else {
        Get-GitResolvedBranch $Branch
    }
    $cmnd = "git rebase $resolvedBranch"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function grbo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command strings
    if ($remote = @(git remote)[0]) {
        # get current branch
        $currentBranch = git branch --show-current
        # resolve provided branch
        $resolvedBranch = Get-GitResolvedBranch $Branch
        $PSBoundParameters.Remove('Branch') | Out-Null
        # build list of commands to execute
        $commands = [System.Collections.Generic.List[string]]::new()
        $commands.Add("git fetch $remote --prune")
        if ($currentBranch -ne $resolvedBranch) {
            $commands.Add("git rebase ${remote}/${currentBranch} --quiet")
        }
        $commands.Add("git rebase ${remote}/${resolvedBranch}")
    } else {
        Write-Host 'fatal: Remote repository not set.'
        return
    }

    # run commands
    foreach ($cmnd in $commands) {
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    }
}
function gmb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git merge-base $(Get-GitResolvedBranch $Branch) HEAD"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function grmb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git reset `$(git merge-base $(Get-GitResolvedBranch $Branch) HEAD)"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
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
    # prepare commands to execute
    $cmd = {
        # calculate arguments
        $defaultBranch = Get-GitResolvedBranch
        $remote = @(git remote)[0]

        # run git commands
        git fetch --all --tags --prune --prune-tags --force
        $switch = Invoke-WriteExecCommand -Command "git switch $defaultBranch"
        # run commands if switched branch successfully
        if ($?) {
            if ($switch -ne "Your branch is up to date with '$remote/$defaultBranch'.") {
                Invoke-WriteExecCommand -Command "git merge ${remote}/${defaultBranch}"
            }
            Remove-GitMergedBranches
        }
    }
    # run git repository command
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


#region git stash functions
function gstaap {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter({ ArgGitGetStashList @args })]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # command string
    $cmnd = 'git stash apply --force'
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gstad {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter({ ArgGitGetStashList @args })]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # command string
    $cmnd = 'git stash drop'
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gstas {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter({ ArgGitGetStashList @args })]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # command string
    $cmnd = 'git stash show'
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gstast {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter({ ArgGitGetStashList @args })]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # command string
    $cmnd = 'git stash show --text'
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
#endregion


#region helper switch functions
function gsw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git switch $(Get-GitResolvedBranch $Branch)"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gsw! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git switch $(Get-GitResolvedBranch $Branch) --force"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
#endregion
