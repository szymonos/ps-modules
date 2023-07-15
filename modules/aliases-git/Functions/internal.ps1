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
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [int]$Count,

        [switch]$All,

        [string]$Grep
    )

    begin {
        # initialize list with CSV header for the execution results
        $csv = [System.Collections.Generic.List[string]]::new([string[]]"Commit`fDate`fReference`fSubject`fAuthor`fEmail")
        # build format string array
        $format = $(
            ($Grep ? " --grep '$Grep' --perl-regexp --regexp-ignore-case" : ''),
            ($All ? ' --all' : ''),
            ($Count ? " -$Count" : '')
        )
        # build git expression
        $cmd = "git log{0}{1} --pretty=format:`"%h`f%ai`f%D`f%s`f%an`f%ae`"{2}" -f $format
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
                @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s') } }
                @{ Name = 'Reference'; Expression = { $_.Reference.Replace('origin/', '').Split(',')[0] } }
                'Subject'
                'Author'
                'Email'
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
        $Arguments = $Arguments.Where({ $_ -notmatch '^-WhatIf$|^-Quiet$' }).ForEach({ $_ -match '\s' ? "'$_'" : $_ })
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
        [string]$BranchName = $BranchName.Where({ $_ -notmatch '^-WhatIf$|^-Quiet$' })
        $branchMatch = switch ($BranchName) {
            '' { '(^|/)dev(|el|elop|elopment)$|(^|/)ma(in|ster)$|(^|/)trunk$'; continue }
            d { '(^|/)dev(|el|elop|elopment)$'; continue }
            m { '(^|/)ma(in|ster)$'; continue }
            s { '(^|/)stage$'; continue }
            t { '(^|/)trunk$'; continue }
            Default { "(^|/)$BranchName$" }
        }
    }

    process {
        [string[]]$branches = (git branch --all --format='%(refname:short)').Where({ $_ -ne 'origin/HEAD' }).Replace('origin/', '')
        if ($branches) {
            $branch = $branches | Sort-Object -Unique | Select-String $branchMatch -Raw | Select-Object -First 1
        }
        if (-not $branch) {
            if ($BranchName) {
                Write-Host "invalid reference: $BranchName`nvalid branch names: $branches"
            }
            break
        }
    }

    end {
        return $branch
    }
}

<#
.SYNOPSIS
Clean local branches.

.PARAMETER DeleteNoMerged
Switch whether to delete no merged branches.
.PARAMETER WhatIf
Switch whether to see what the command would have done instead of making changes.
#>
function Remove-GitLocalBranches {
    param (
        [switch]$DeleteNoMerged,

        [switch]$WhatIf,

        [switch]$Quiet
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
        # *get list of branches
        filter branchFilter { $_.Where({ $_ -notmatch '^ma(in|ster)$|^dev(|el|elop)$|^qa$|^stage$|^trunk$' }) }
        $merged = git branch --format='%(refname:short)' --merged | branchFilter
        # *delete branches
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
