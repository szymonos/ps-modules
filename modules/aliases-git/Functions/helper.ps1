<#
.SYNOPSIS
Get git log object.

.PARAMETER All
Switch whether to get all commits, otherwise only last 50 will be shown.
.PARAMETER Quiet
Switch whether to write command.
#>
function Get-GitLogObject {
    param (
        [switch]$All,

        [switch]$Quiet
    )
    $cmd = "git log --pretty=format:`"%h`f%ai`f%s`f%an <%ae>`"$($All ? '' : ' -50')"
    if (-not $Quiet) {
        Write-Host $cmd.Replace("`f", '`f') -ForegroundColor Magenta
    }
    [string[]]$commit = Invoke-Expression $cmd
    if ($commit) {
        @("Commit`fDate`fSubject`fAuthor", $commit) `
        | ConvertFrom-Csv -Delimiter "`f" `
        | Select-Object Commit, @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s') } }, Subject, Author `
        | Sort-Object DateUTC
    }
}

Set-Alias -Name gglo -Value Get-GitLogObject

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

Set-Alias -Name gbda -Value Remove-GitLocalBranches
