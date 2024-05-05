<#
.SYNOPSIS
Get list of git branches for the function ArgumentCompleter attribute.
#>
function ArgGitGetBranches {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # instantiate SortedSet
    $branches = [System.Collections.Generic.SortedSet[string]]::new()

    # get list of all branches
    $branchList = git branch --all --format='%(refname:short)'
    # build remote names filter
    $remoteFilter = [string]::Join('|', (git remote).ForEach({ "$_/?" }))

    $branchList -replace $remoteFilter `
    | Where-Object { $_ } `
    | ForEach-Object { $branches.Add($_) | Out-Null }

    # get namespaces
    [string[]]$possibleValues = $branches

    # return matching namespaces
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}
