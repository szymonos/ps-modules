<#
.SYNOPSIS
Get git log object.

.PARAMETER All
Switch whether to get commits from all branches.
.PARAMETER Grep
Specify regex expression to search in the commit subjects
.PARAMETER Count
Specify number of results to be returned

.EXAMPLE
Get-GitLogObject
Get-GitLogObject -Count 10
Get-GitLogObject -All -Grep '^feat.*aliases-git' -Verbose
#>
function Get-GitLogObject {
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

    begin {
        # initialize list with CSV header for the execution results
        $csv = [System.Collections.Generic.List[string]]::new([string[]]"Commit`fDate`fSubject`fAuthor`fEmail`fRef")
        # build format string array
        $format = $(
            ($Grep ? " --grep '$Grep' --perl-regexp --regexp-ignore-case" : ''),
            ($All ? ' --all' : ($Tags ? ' --no-walk --tags="*"' : '')),
            ($Count ? " -$Count" : '')
        )
        # build git expression
        $cmd = "git log{0}{1} --pretty=format:`"%h`f%ai`f%s`f%an`f%ae`f%D`"{2}" -f $format
        # show the expression
        Write-Verbose $cmd.Replace("`f", ' ')
    }

    process {
        # execute formatted expression
        (Invoke-Expression $cmd).ForEach({ $csv.Add($_) })
        if ($csv.Count -gt 1) {
            # build properties for Select-Object
            $prop = @(
                'Commit'
                @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s').Replace('T', ' ') } }
                'Subject'
                'Author'
                'Email'
                'Ref'
            )
            $result = $csv | ConvertFrom-Csv -Delimiter "`f" | Select-Object -Property $prop
        }
    }

    end {
        return $result
    }
}


<#
.SYNOPSIS
Write provided command with its arguments and then execute it.
You can suppress writing the command by providing -Quiet as one of the arguments.
You can suppress executing the command by providing -WhatIf as one of the arguments.

.PARAMETER Command
Command to be executed.
.PARAMETER Arguments
Command arguments to be passed to the provided command.
.PARAMETER Parameters
Control parameters: WhatIf, Quiet.
#>
function Invoke-WriteExecCmd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Command,

        [Parameter(ParameterSetName = 'Arguments')]
        [string[]]$Arguments,

        [Parameter(ParameterSetName = 'Parameters')]
        [string[]]$Parameters
    )

    begin {
        # clean up command from control parameters
        $Command = $Command -replace (' -WhatIf| -Quiet')
        # calculate control parameters
        $Parameters = $($Parameters ? $Parameters : $Arguments).Where({ $_ -match '^-WhatIf$|^-Quiet$' })
        # remove control parameters from arguments and quote arguments with spaces
        $Arguments = $Arguments.Where({ $_ -notmatch '^-WhatIf$|^-Quiet$' }).ForEach({ $_ -match '\s|''|"' ? "'$($_.Replace("'", "''"))'" : $_ })
        # build the command expression
        $cmd = "$Command $Arguments"
    }

    process {
        if ('-Quiet' -notin $Parameters) {
            # write the command
            Write-Host $cmd -ForegroundColor Magenta
        }
        if ('-WhatIf' -notin $Parameters) {
            # execute the command
            Invoke-Expression $cmd
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

    begin {
        if (git rev-parse --is-inside-work-tree) {
            [string]$BranchName = $BranchName.Where({ $_ -notmatch '^-WhatIf$|^-Quiet$' })
            $match = @{
                d = @('^dev(|el|elop|elopment)$')
                m = @('^ma(in|ster)$', '^prod(uction)?$')
                s = @('^stag(e|ing)$')
                t = @('^trunk$')
            }
            $branchMatch = switch ($BranchName) {
                '' { $match.m + $match.d + $match.t; continue }
                d { $match.d; continue }
                m { $match.m; continue }
                s { $match.s; continue }
                t { $match.t; continue }
                Default { @("(^|/)$BranchName$") }
            }
            # instantiate HashSet
            $matched = [System.Collections.Generic.HashSet[string]]::new()
        } else {
            break
        }
    }

    process {
        # build remote names filter
        $remoteFilter = [string]::Join('|', (git remote).ForEach({ "$_/?" }))
        # get list of branches without remote name indicator
        [string[]]$branches = ((git branch --all --format='%(refname:short)') -replace $remoteFilter).Where({ $_ })
        # get set of matching branches in specified order
        $branchMatch.ForEach({
                ($branches -match $_).ForEach({ $matched.Add($_) | Out-Null })
            }
        )

        # return if no matching branches found
        if ($matched.Count -eq 0) {
            if ($BranchName) {
                Write-Host "`e[92mInvalid reference  :`e[0m $BranchName"
                Write-Host "`e[92mValid branch names :`e[0m $([string]::Join(', ', $branches))"
                break
            } else {
                $matched.Add($(git branch --format='%(refname:short)')) | Out-Null
            }
        }
    }

    end {
        return $matched | Select-Object -First 1
    }
}


<#
.SYNOPSIS
Delete local branches.
.DESCRIPTION
If DeleteNoMerged parameter is not specified, all local merged branches will be deleted.

.PARAMETER DeleteNoMerged
Switch whether to delete non merged branches.
#>
function Remove-GitLocalBranches {
    param (
        [switch]$DeleteNoMerged
    )

    begin {
        # remove DeleteNoMerged from PSBoundParameters
        $PSBoundParameters.Remove('DeleteNoMerged') | Out-Null
        # switch to dev/main branch
        git switch $(Get-GitResolvedBranch) --quiet
        # update remote
        git remote update --prune
    }

    process {
        # get list of branches
        filter branchFilter { $_.Where({ $_ -notmatch '^ma(in|ster)$|^dev(|el|elop)$|^qa$|^stage$|^trunk$' }) }
        $merged = git branch --format='%(refname:short)' --merged | branchFilter
        # delete branches
        foreach ($branch in $merged) {
            Invoke-WriteExecCmd -Command "git branch --delete $branch" @PSBoundParameters
        }
        if ($DeleteNoMerged) {
            $no_merged = git branch --format='%(refname:short)' --no-merged | branchFilter
            foreach ($branch in $no_merged) {
                if ((Read-Host -Prompt "Do you want to remove branch: `e[1;97m$branch`e[0m? [y/N]") -eq 'y') {
                    Invoke-WriteExecCmd -Command "git branch -D $branch" @PSBoundParameters
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
#>
function Remove-GitMergedBranches {
    param (
        [switch]$DeleteRemote
    )

    begin {
        # switch to dev/main branch
        git switch $(Get-GitResolvedBranch) --quiet
        # update remote
        git remote update --prune

        # build branch filters
        filter localFilter { $_.Where({ $_ -notmatch '^ma(in|ster)$|^dev(|el|elop)$|^qa$|^stage$|^trunk$' }) }
        if ($DeleteRemote) {
            [string[]]$remotes = git remote
            $remoteFilter = $remotes.ForEach({ "^$_/" }) | Join-String -Separator '|'
            $knownFilter = "($remoteFilter)(ma(in|ster)$|dev(|el|elop)$|qa$|stage$|trunk$)"
            filter remoteFilter { $_.Where({ $_ -match $remoteFilter -and $_ -notmatch $knownFilter }) }
        }
    }

    process {
        # remove local merged branches
        [string[]]$mergedLocal = git branch --format='%(refname:short)' --merged | localFilter
        foreach ($branch in $mergedLocal) {
            git branch --delete $branch
        }

        # remove remote merged branches
        if ($DeleteRemote) {
            [string[]]$mergedRemote = git branch --remotes --format='%(refname:short)' --merged | remoteFilter
            foreach ($remote in $remotes) {
                $mergedRemote | Select-String "^$remote/(.*)" | ForEach-Object {
                    git push --delete $remote $_.Matches.Groups[1].Value
                }
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
#>
function Invoke-GitRepoCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The command to be invoked.')]
        [scriptblock]$Command
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

    # iterate over all git repos with remote set
    foreach ($dir in $dirs) {
        Set-Location $dir
        # set line separator for printing the following results
        $follow = $dir -eq $dirs[0] ? '' : "`n"
        Write-Host "$follow$($dir.Name)" -ForegroundColor Cyan
        # execute commands
        Invoke-Command -ScriptBlock $Command
    }

    Pop-Location
}
