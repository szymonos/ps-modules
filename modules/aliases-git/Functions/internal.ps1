<#
.SYNOPSIS
Get git log object.

.PARAMETER Xargs
Additional arguments to pass to the git log command.
#>
function Get-GitLogObject {
    [CmdletBinding()]
    param (
        [switch]$All,

        [switch]$Grep,

        [switch]$Limit,

        [switch]$Tags,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    begin {
        #region build arguments list
        # build git log command arguments
        $cmdArgs = [System.Collections.Generic.List[string]]::new(
            [string[]]@(
                '--reverse'
                "--pretty=format:%h`f%ai`f%s`f%an`f%ae`f%D"
            )
        )
        # limit result to 30
        if ($PSBoundParameters.Limit -and $PSBoundParameters.Xargs -notmatch '^(-?\d+)$') {
            $cmdArgs.Add('-30')
        }
        # return commits from all branches
        if ($PSBoundParameters.All) {
            $cmdArgs.Add('--all')
        }
        # add additional grep filter parameters
        if ($PSBoundParameters.Grep) {
            $cmdArgs.AddRange(
                [string[]]@(
                    '--perl-regexp'
                    '--regexp-ignore-case'
                )
            )
        }
        # return tags only
        if ($PSBoundParameters.Tags) {
            $cmdArgs.AddRange(
                [string[]]@(
                    '--tags=*'
                    '--no-walk'
                )
            )
        }
        # parse Xargs for count specification
        $parsedXargs = if ($PSBoundParameters.Xargs -match '^0$') {
            $Xargs -notmatch '^0$'
        } elseif ($PSBoundParameters.Xargs -match '^\d+$') {
            $Xargs -replace '^\d+$', "-`$&"
        } else {
            $Xargs
        }

        if ($parsedXargs) {
            $cmdArgs.AddRange([string[]]$parsedXargs)
        }
        #endregion

        #region specify headers and output parameters
        # specify CSV headers
        $headers = @(
            'Commit'
            'Date'
            'Subject'
            'Author'
            'Email'
            'Ref'
        )
        # property selection
        $prop = @(
            'Commit'
            @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s').Replace('T', ' ') } }
            'Subject'
            'Author'
            'Email'
            'Ref'
        )
        #endregion
    }

    process {
        # show the expression
        Write-Verbose "git log $cmdArgs".Replace("`f", ' ').Replace('%h', '"$h').Replace('%D', '$D"')
        # run git log and convert output to objects
        $result = git log @cmdArgs | ConvertFrom-Csv -Delimiter "`f" -Header $headers | Select-Object -Property $prop
    }

    end {
        return $result
    }
}


<#
.SYNOPSIS
Get git reflog object.

.PARAMETER Xargs
Additional arguments to pass to the git reflog command.
#>
function Get-GitReflogObject {
    [CmdletBinding()]
    param (
        [switch]$Limit,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    begin {
        #region build arguments list
        # build git reflog command arguments
        $cmdArgs = [System.Collections.Generic.List[string]]::new(
            [string[]]@(
                "--format=%h`f%gd`f%ai`f%gs`f%an`f%ae`f%D"
            )
        )
        # limit result to 30
        if ($PSBoundParameters.Limit -and $PSBoundParameters.Xargs -notmatch '^(-?\d+)$') {
            $cmdArgs.Add('-30')
        }
        # parse Xargs for count specification
        $parsedXargs = if ($PSBoundParameters.Xargs -match '^0$') {
            $Xargs -notmatch '^0$'
        } elseif ($PSBoundParameters.Xargs -match '^\d+$') {
            $Xargs -replace '^\d+$', "-`$&"
        } else {
            $Xargs
        }

        if ($parsedXargs) {
            $cmdArgs.AddRange([string[]]$parsedXargs)
        }
        #endregion

        #region specify headers and output parameters
        # specify CSV headers
        $headers = @(
            'Commit'
            'Selector'
            'Date'
            'Subject'
            'Author'
            'Email'
            'Ref'
        )
        # property selection
        $prop = @(
            'Commit'
            'Selector'
            @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s').Replace('T', ' ') } }
            'Subject'
            'Author'
            'Email'
            'Ref'
        )
        #endregion
    }

    process {
        # show the expression
        Write-Verbose "git reflog $cmdArgs".Replace("`f", ' ').Replace('%h', '"$h').Replace('%D', '$D"')
        # run git reflog and convert output to objects, reverse to show oldest first
        [array]$result = git reflog @cmdArgs | ConvertFrom-Csv -Delimiter "`f" -Header $headers | Select-Object -Property $prop
        [array]::Reverse($result)
    }

    end {
        return $result
    }
}


<#
.SYNOPSIS
Get last git commit message.

.PARAMETER First
Switch whether to return only the first line of the commit message.
#>
function Get-GitLogMessage ([switch]$First) {
    # get the last commit message
    $msg = (git log -1 --pretty=%B).ForEach({ "$_".Trim() }).Where({ $_ })

    # return first line or full message
    if ($PSBoundParameters.First) {
        $msg | Select-Object -First 1
    } else {
        $msg -join ' '
    }
}

<#
.SYNOPSIS
Write provided command with its arguments and then execute it.
You can suppress writing the command by providing -Quiet as one of the arguments.
You can suppress executing the command by providing -WhatIf as one of the arguments.

.PARAMETER Command
Command to be executed.
.PARAMETER Xargs
Command arguments to be passed to the provided command.
.PARAMETER WhatIf
Do not execute the command.
.PARAMETER Quiet
Do not print the command string.
.PARAMETER NoVerify
Append --no-verify after all arguments to skip git hooks (pre-commit/pre-push).
Not compatible with a '--' pathspec on commit (git treats trailing args as
pathspecs); in that rare case pass --no-verify manually before the '--'.
#>
function Invoke-WriteExecCommand {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet,

        [switch]$NoVerify
    )

    begin {
        # build command
        $sb = [System.Text.StringBuilder]::new($Command)
        if ($PSBoundParameters.Xargs) {
            $Xargs | ForEach-Object {
                $arg = $_ -match '\s|@' ? "'$_'" : $_
                $sb.Append(" $arg") | Out-Null
            }
        }
        # append --no-verify after all arguments (correct position for both push and -m commit)
        if ($NoVerify) {
            $sb.Append(' --no-verify') | Out-Null
        }
        # get command string
        $cmnd = $sb.ToString()
    }

    process {
        if (-not $PSBoundParameters.Quiet) {
            # write command
            Write-Host $cmnd -ForegroundColor Magenta
        }
        if (-not $PSBoundParameters.WhatIf) {
            # execute command
            return Invoke-Expression $cmnd
        }
    }
}


<#
.SYNOPSIS
Get current branch name.
#>
function Get-GitCurrentBranch {
    git branch --show-current
}


<#
.SYNOPSIS
Resolve main, dev, stage branch names.

.PARAMETER BranchName
Name of the branch to switch to.
#>
function Get-GitResolvedBranch {
    [CmdletBinding()]
    param (
        [string[]]$BranchName
    )

    if (git rev-parse --is-inside-work-tree) {
        # build remote names filter
        filter remoteFilter {
            "$_".Trim() -replace [string]::Join('|', (git remote).ForEach({ "$_/?" })) | Where-Object { $_ }
        }
        [string]$BranchName = $BranchName | remoteFilter
        $match = @{
            d = @('^dev(|el|elop|elopment)$')
            m = @('^ma(in|ster)$')
            p = @('^prod(uction)?$')
            s = @('^st(g|age|aging)$')
            t = @('^trunk$')
        }
        $branchMatch = switch ($BranchName) {
            '' { $match.m + $match.p + $match.s + $match.d + $match.t; break }
            d { $match.d; break }
            m { $match.m; break }
            p { $match.p; break }
            s { $match.s; break }
            t { $match.t; break }
            default { @("^$BranchName$") }
        }
        Write-Verbose "BranchMatch: $($branchMatch -join ', ')"
        # instantiate collections
        $matched = [System.Collections.Generic.HashSet[string]]::new()
    } else {
        break
    }

    # get list of branches
    $branches = git branch --all --format='%(refname:short)' | remoteFilter | Sort-Object -Unique
    # match branches
    foreach ($match in $branchMatch) {
        $branches.Where({ $_ -match $match }).ForEach({ $matched.Add($_) | Out-Null })
    }
    Write-Verbose "Matched branches: $($matched -join ', ')"

    if ($matched.Count -eq 0) {
        if ($BranchName) {
            Write-Warning "Invalid reference: '$BranchName'. Valid reference values are: `e[0;1m$([string]::Join(', ', $branches))`e[0m"
            break
        } else {
            $matched = Get-GitCurrentBranch
        }
    }

    return $matched | Select-Object -First 1
}


<#
.SYNOPSIS
Delete local branches.
.DESCRIPTION
If DeleteNoMerged parameter is not specified, all local merged branches will be deleted.

.PARAMETER DeleteNoMerged
Switch whether to delete non merged branches.
.PARAMETER NoFetch
Switch whether to skip updating the remote, for callers that have already fetched.
#>
function Remove-GitLocalBranches {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [switch]$DeleteNoMerged,

        [switch]$NoFetch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    begin {
        # remove DeleteNoMerged and NoFetch from PSBoundParameters
        $PSBoundParameters.Remove('DeleteNoMerged') | Out-Null
        $PSBoundParameters.Remove('NoFetch') | Out-Null
        # set locally, so a caller's $skip cannot leak in through dynamic scoping
        $skip = $false
        # switch to dev/main branch, a failed switch leaves --merged comparing against the feature HEAD
        git switch $(Get-GitResolvedBranch) --quiet
        if ($LASTEXITCODE) {
            Write-Warning 'Cannot switch to the base branch, skipped branch cleanup.'
            $skip = $true
            return
        }
        # update remote
        if (-not $NoFetch) {
            git remote update --prune
        }
        # instantiate sorted set for branches to delete, git branch names are case-sensitive
        $branches = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::Ordinal)
        $gone = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        $regex = '^(ma(in|ster)|(non)?prod(uction)?|dev(|el|elop|elopment)|qa|stag(e|ing)|trunk|docs)$'
        filter branchFilter { $_.Where({ $_ -notmatch $regex }) }
    }

    process {
        if ($skip) { return }
        # add merged branches
        git branch --format='%(refname:short)' --merged | branchFilter | ForEach-Object { $branches.Add($_) | Out-Null }
        # add branches with gone upstream (e.g. squash-merged PRs)
        git branch --format='%(refname:short) %(upstream:track)' | ForEach-Object {
            if ($_ -match '^(\S+)\s+\[gone\]$') { $Matches[1] }
        } | branchFilter | ForEach-Object { $branches.Add($_) | Out-Null; $gone.Add($_) | Out-Null }
        # map branches to the worktrees they are checked out in, -z keeps unusual paths unquoted and whole
        # rejoin, PowerShell splits native output on newlines inside a path
        $current = (git rev-parse --show-toplevel) -join "`n"
        $worktrees = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::Ordinal)
        ((git worktree list --porcelain -z) -join "`n").Split("`0") | ForEach-Object {
            if ($_ -match '(?s)^worktree (.+)$') { $path = $Matches[1] }
            elseif ($_ -match '^branch refs/heads/(.+)$') { $worktrees[$Matches[1]] = $path }
        }
        # delete merged and gone branches
        foreach ($branch in $branches) {
            if ($worktrees.ContainsKey($branch)) {
                # remove only worktrees of gone branches
                if (-not $gone.Contains($branch)) { continue }
                # never the one cleanup runs from, git removes it without complaint
                # ignore case, so a case-insensitive filesystem cannot hide a match; a false match only keeps a worktree
                if ([string]::Equals($worktrees[$branch], $current, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
                # keep worktrees tracking a branch of another name, e.g. new ones cut from origin/main
                if (-not [string]::Equals((git config "branch.$branch.merge"), "refs/heads/$branch", [System.StringComparison]::Ordinal)) { continue }
                if ($PSBoundParameters.WhatIf) {
                    Invoke-WriteExecCommand -Command "git worktree remove '$($worktrees[$branch])'" -WhatIf
                } else {
                    # without --force, git refuses to remove worktrees with uncommitted changes
                    git worktree remove $worktrees[$branch] 2>$null
                    if ($LASTEXITCODE) {
                        Write-Host "Kept worktree $($worktrees[$branch]) (uncommitted changes or locked)" -ForegroundColor DarkGray
                        continue
                    }
                    Write-Host "Removed worktree $($worktrees[$branch])" -ForegroundColor DarkYellow
                }
            }
            Invoke-WriteExecCommand -Command "git branch -D $branch" @PSBoundParameters
        }
        if ($DeleteNoMerged) {
            $no_merged = git branch --format='%(refname:short)' --no-merged | branchFilter
            foreach ($branch in $no_merged) {
                if ((Read-Host -Prompt "Do you want to remove branch: `e[1;97m$branch`e[0m? [y/N]") -eq 'y') {
                    Invoke-WriteExecCommand -Command "git branch -D $branch" @PSBoundParameters
                }
            }
        }
    }
}


<#
.SYNOPSIS
Delete merged branches.

.PARAMETER DeleteRemote
Switch whether to delete remote merged branches.
.PARAMETER NoFetch
Switch whether to skip updating the remote, for callers that have already fetched.
#>
function Remove-GitMergedBranches {
    param (
        [switch]$DeleteRemote,

        [switch]$NoFetch
    )

    # remove local merged and gone branches
    Remove-GitLocalBranches -Quiet -NoFetch:$NoFetch

    # remove remote merged branches
    if ($DeleteRemote) {
        $regex = '^(ma(in|ster)|(non)?prod(uction)?|dev(|el|elop|elopment)|qa|stag(e|ing)|trunk|docs)$'
        [string[]]$remotes = git remote
        $remoteFilter = $remotes.ForEach({ "^$_/" }) | Join-String -Separator '|'
        $knownFilter = "($remoteFilter)($($regex.Replace('^', '')))"
        filter remoteFilter { $_.Where({ $_ -match $remoteFilter -and $_ -notmatch $knownFilter }) }
        [string[]]$mergedRemote = git branch --remotes --format='%(refname:short)' --merged | remoteFilter
        foreach ($remote in $remotes) {
            $mergedRemote | Select-String "^$remote/(.*)" | ForEach-Object {
                git push --delete $remote $_.Matches.Groups[1].Value
            }
        }
    }
}


<#
.SYNOPSIS
Run specified git commands in a current repo or all repos located in subdirectories of the current folder.
Function runs only for repositories with remote set.

.PARAMETER Command
Script block of commands to execute.
.PARAMETER Fetch
Switch whether to fetch all repositories in parallel before executing the commands.
#>
function Invoke-GitRepoCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The command to be invoked.')]
        [scriptblock]$Command,

        [switch]$Fetch
    )

    Push-Location
    # instantiate list for storing git directories with remote set
    $dirs = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()

    # check if in git repo
    $isGitRepo = git rev-parse --is-inside-work-tree 2>$null && $true || $false
    # build list of directories with remote set
    if ($isGitRepo) {
        (git remote) ? $dirs.Add($(Get-Item .)) : $null
    } else {
        Get-ChildItem -Directory | ForEach-Object {
            (git -C $_.FullName remote 2>$null) ? $dirs.Add($_) : $null
        }
    }

    # fetch repositories in parallel, since fetching is network-bound and dominates the run time
    if ($Fetch) {
        # fetch each repository once, sibling directories can be worktrees sharing its refs
        # a directory whose common dir cannot be resolved is fetched on its own
        # keys compare ordinally, Group-Object would merge paths that differ only in Unicode normalization
        $repos = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[System.IO.DirectoryInfo]]]::new([System.StringComparer]::Ordinal)
        foreach ($dir in $dirs) {
            $commonDir = (git -C $dir.FullName rev-parse --git-common-dir 2>$null) -join "`n"
            $key = $LASTEXITCODE ? $dir.FullName : [System.IO.Path]::GetFullPath($commonDir, $dir.FullName)
            if (-not $repos.ContainsKey($key)) { $repos[$key] = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new() }
            $repos[$key].Add($dir)
        }
        $fetched = [System.Collections.Generic.HashSet[string]]::new()
        # ponytail: one time limit for the whole batch, a hung fetch skips repositories still queued behind it
        try {
            $repos.Values | ForEach-Object -ThrottleLimit 16 -TimeoutSeconds 300 -Parallel {
                $out = git -C $_[0].FullName -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 `
                    fetch --all --tags --prune --prune-tags --force --quiet 2>&1
                if ($LASTEXITCODE) {
                    Write-Warning "$($_[0].Name): $($out -join "`n")"
                } else {
                    $_.FullName
                }
            } | ForEach-Object { $fetched.Add($_) | Out-Null }
        } catch {
            Write-Warning 'Fetching timed out.'
        }
    }

    # iterate over all git repos with remote set
    foreach ($dir in $dirs) {
        # skip worktrees removed by the cleanup of a sibling directory
        if (-not (Test-Path -LiteralPath $dir.FullName)) { continue }
        Set-Location -LiteralPath $dir.FullName
        # set line separator for printing the following results
        $follow = $dir -eq $dirs[0] ? '' : "`n"
        if ($dirs.Count -gt 1) {
            Write-Host "$follow$($dir.Name)" -ForegroundColor Cyan
        }
        # skip commands that would act on stale refs
        if ($Fetch -and -not $fetched.Contains($dir.FullName)) {
            Write-Warning "$($dir.Name): fetch failed or timed out, skipped."
            continue
        }
        # execute commands
        Invoke-Command -ScriptBlock $Command
    }

    Pop-Location
}
