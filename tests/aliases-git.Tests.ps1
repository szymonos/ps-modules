#Requires -Modules Pester
<#
.SYNOPSIS
Branch cleanup safety tests for aliases-git.

.EXAMPLE
Invoke-Pester ./tests/aliases-git.Tests.ps1
#>

BeforeAll {
    Import-Module "$PSScriptRoot/../modules/aliases-git/aliases-git.psd1" -Force
    # test identity for the throwaway repos, restored in AfterAll
    $gitIdentity = 'GIT_AUTHOR_NAME', 'GIT_COMMITTER_NAME', 'GIT_AUTHOR_EMAIL', 'GIT_COMMITTER_EMAIL' |
        ForEach-Object -Begin { $saved = @{} } -Process { $saved[$_] = [Environment]::GetEnvironmentVariable($_) } -End { $saved }
    $env:GIT_AUTHOR_NAME = $env:GIT_COMMITTER_NAME = 'test'
    $env:GIT_AUTHOR_EMAIL = $env:GIT_COMMITTER_EMAIL = 'test@example.com'

    # bare remote plus a clone with one commit on main, returns the clone path
    function New-TestRepo {
        $root = Join-Path $TestDrive ([guid]::NewGuid())
        git init --quiet --bare -b main "$root/remote.git"
        git clone --quiet "$root/remote.git" "$root/repo" 2>$null
        git -C "$root/repo" commit --quiet --allow-empty -m init
        git -C "$root/repo" push --quiet -u origin main 2>$null
        return "$root/repo"
    }

    # push a branch with its own commit, then delete it on the remote so its upstream is gone
    function New-GoneBranch ([string]$Repo, [string]$Branch, [string]$Path) {
        git -C $Repo worktree add --quiet -b $Branch $Path main 2>$null
        git -C $Path commit --quiet --allow-empty -m $Branch
        git -C $Path push --quiet -u origin $Branch 2>$null
        git -C $Repo push --quiet origin --delete $Branch 2>$null
    }

    function Invoke-Cleanup ([string]$Path) {
        Push-Location $Path
        try { InModuleScope aliases-git { Remove-GitLocalBranches -Quiet -NoFetch } 6>$null }
        finally { Pop-Location }
    }
}

AfterAll {
    $gitIdentity.GetEnumerator() | ForEach-Object { [Environment]::SetEnvironmentVariable($_.Key, $_.Value) }
}

Describe 'Remove-GitLocalBranches worktree removal' {
    It 'removes the worktree of a gone branch' {
        $repo = New-TestRepo
        New-GoneBranch $repo 'gone' "$repo-gone"
        Invoke-Cleanup $repo
        "$repo-gone" | Should -Not -Exist
        git -C $repo branch --list gone | Should -BeNullOrEmpty
    }

    It 'keeps the worktree of a merged branch whose upstream still exists' {
        $repo = New-TestRepo
        git -C $repo worktree add --quiet -b merged "$repo-merged" main 2>$null
        git -C "$repo-merged" push --quiet -u origin merged 2>$null
        Invoke-Cleanup $repo
        "$repo-merged" | Should -Exist
    }

    It 'keeps the worktree of a never-pushed branch cut from origin/main' {
        $repo = New-TestRepo
        git -C $repo worktree add --quiet -b feature "$repo-feature" origin/main 2>$null
        Invoke-Cleanup $repo
        "$repo-feature" | Should -Exist
    }

    It 'keeps a worktree whose upstream has a different name' {
        $repo = New-TestRepo
        New-GoneBranch $repo 'other' "$repo-other"
        git -C $repo worktree add --quiet -b local "$repo-local" main 2>$null
        git -C $repo config branch.local.remote origin
        git -C $repo config branch.local.merge refs/heads/other
        Invoke-Cleanup $repo
        "$repo-local" | Should -Exist
    }

    It 'stops when it cannot switch to the base branch and keeps the current worktree' {
        $repo = New-TestRepo
        New-GoneBranch $repo 'gone' "$repo-gone"
        Invoke-Cleanup "$repo-gone" 2>$null 3>$null
        "$repo-gone" | Should -Exist
    }

    It 'removes worktrees at paths with spaces, newlines and non-ASCII characters' {
        $repo = New-TestRepo
        # newlines split the path in porcelain output without -z, Windows forbids them in paths
        $path = "$repo-za$([char]0x017C)$([char]0x00F3)$([char]0x0142)$([char]0x0107) gone$($IsWindows ? '' : "`nline")"
        New-GoneBranch $repo 'gone' $path
        Invoke-Cleanup $repo
        $path | Should -Not -Exist
    }

    It 'keeps branches apart that differ only by case' -Skip:(-not $IsLinux) {
        $repo = New-TestRepo
        New-GoneBranch $repo 'feature' "$repo-lower"
        git -C $repo worktree add --quiet -b Feature "$repo-upper" main 2>$null
        git -C "$repo-upper" push --quiet -u origin Feature 2>$null
        Invoke-Cleanup $repo
        "$repo-lower" | Should -Not -Exist
        "$repo-upper" | Should -Exist
    }
}

Describe 'Invoke-GitRepoCommand' {
    It 'skips the command in a repository whose fetch failed' {
        $repo = New-TestRepo
        git -C $repo remote set-url origin "$TestDrive/missing.git"
        Push-Location $repo
        try {
            $ran = InModuleScope aliases-git { Invoke-GitRepoCommand -Fetch -Command { 'ran' } } 3>$null
        } finally { Pop-Location }
        $ran | Should -BeNullOrEmpty
    }

    It 'runs the command in a directory whose name has wildcard characters' {
        $repo = New-TestRepo
        $dir = New-Item -ItemType Directory (Join-Path $TestDrive ([guid]::NewGuid()))
        Move-Item -LiteralPath $repo -Destination "$dir/repo-[c]"
        Push-Location $dir
        try {
            $ran = InModuleScope aliases-git { Invoke-GitRepoCommand -Command { 'ran' } } 6>$null
        } finally { Pop-Location }
        $ran | Should -Be 'ran'
    }
}
