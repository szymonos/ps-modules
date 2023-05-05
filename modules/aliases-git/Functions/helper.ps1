<#
.SYNOPSIS
Get-GitLogObject function aliases.
#>
function gglo {
    Get-GitLogObject | Select-Object Commit, DateUTC, Subject, Author
}
function ggloa {
    Get-GitLogObject -All | Select-Object Commit, DateUTC, Subject, Author
}
function gglos {
    Get-GitLogObject -Start | Select-Object Commit, DateUTC, Subject, Author
}
function gglosa {
    Get-GitLogObject -Start -All | Select-Object Commit, DateUTC, Subject, Author
}

<#
.SYNOPSIS
Get-GitLogObject function colored aliases.
#>
function ggloc {
    Get-GitLogObject | Format-Table @{ Name = 'Commit'; Expression = { "`e[33m$($_.Commit)`e[0m" } } `
        , @{ Name = 'DateUTC'; Expression = { "`e[32m$($_.DateUTC)`e[0m" } } `
        , @{ Name = 'Reference'; Expression = { "`e[31m$($_.Reference.Replace('origin/', '').Split(',')[0])`e[0m" } } `
        , @{ Name = 'Subject'; Expression = { $_.Subject.Length -gt 50 ? $_.Subject.Substring(0, 49) : $_.Subject } } `
        , @{ Name = 'Author'; Expression = { "`e[34;1m$($_.Author)`e[0m" } }
}
function ggloca {
    Get-GitLogObject -All | Format-Table @{ Name = 'Commit'; Expression = { "`e[33m$($_.Commit)`e[0m" } } `
        , @{ Name = 'DateUTC'; Expression = { "`e[32m$($_.DateUTC)`e[0m" } } `
        , @{ Name = 'Reference'; Expression = { "`e[31m$($_.Reference.Replace('origin/', '').Split(',')[0])`e[0m" } } `
        , @{ Name = 'Subject'; Expression = { $_.Subject.Length -gt 50 ? $_.Subject.Substring(0, 49) : $_.Subject } } `
        , @{ Name = 'Author'; Expression = { "`e[34;1m$($_.Author)`e[0m" } }
}
function gglocs {
    Get-GitLogObject -Start | Format-Table @{ Name = 'Commit'; Expression = { "`e[33m$($_.Commit)`e[0m" } } `
        , @{ Name = 'DateUTC'; Expression = { "`e[32m$($_.DateUTC)`e[0m" } } `
        , @{ Name = 'Reference'; Expression = { "`e[31m$($_.Reference.Replace('origin/', '').Split(',')[0])`e[0m" } } `
        , @{ Name = 'Subject'; Expression = { $_.Subject.Length -gt 50 ? $_.Subject.Substring(0, 49) : $_.Subject } } `
        , @{ Name = 'Author'; Expression = { "`e[34;1m$($_.Author)`e[0m" } }
}
function gglocsa {
    Get-GitLogObject -Start -All | Format-Table @{ Name = 'Commit'; Expression = { "`e[33m$($_.Commit)`e[0m" } } `
        , @{ Name = 'DateUTC'; Expression = { "`e[32m$($_.DateUTC)`e[0m" } } `
        , @{ Name = 'Reference'; Expression = { "`e[31m$($_.Reference.Replace('origin/', '').Split(',')[0])`e[0m" } } `
        , @{ Name = 'Subject'; Expression = { $_.Subject.Length -gt 50 ? $_.Subject.Substring(0, 49) : $_.Subject } } `
        , @{ Name = 'Author'; Expression = { "`e[34;1m$($_.Author)`e[0m" } }
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

Set-Alias -Name gbda -Value Remove-GitLocalBranches
