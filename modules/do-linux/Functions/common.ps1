<#
.SYNOPSIS
Run commands as root in PowerShell.
.DESCRIPTION
Wrapper for sudo command to handle defined aliases and one-liner functions.
#>
function Invoke-Sudo {
    for ($i = 0; $i -lt $args.Count; $i++) {
        # expand arguments alias/function definition
        if ($cmd = (Get-ChildItem Alias:/$($args[$i]) -ErrorAction SilentlyContinue || Get-ChildItem Function:/$($args[$i]) -ErrorAction SilentlyContinue).Definition.Where({ $_ -notmatch '\n' })) {
            $args[$i] = "$cmd".Trim().Replace('$input | ', '').Replace('& /usr/bin/env ', '').Replace(' @args', '')
        } elseif ($args[$i] -match ' ') {
            # quote arguments with spaces
            $args[$i] = "'$($args[$i])'"
        }
    }
    & /usr/bin/env bash -c "/usr/bin/env sudo $args"
}

Set-Alias -Name _ -Value Invoke-Sudo

<#
.SYNOPSIS
Run PowerShell cmdlets as root.
.DESCRIPTION
Wrapper for sudo command to execute PowerShell cmdlets and handle defined aliases and one-liner functions.
#>
function Invoke-SudoPS {
    for ($i = 0; $i -lt $args.Count; $i++) {
        # expand arguments alias/function definition
        if ($cmd = (Get-ChildItem Alias:/$($args[$i]) -ErrorAction SilentlyContinue || Get-ChildItem Function:/$($args[$i]) -ErrorAction SilentlyContinue).Definition.Where({ $_ -notmatch '\n' })) {
            $args[$i] = "$cmd".Trim().Replace('$input | ', '').Replace('& /usr/bin/env ', '').Replace(' @args', '')
        } elseif ($args[$i] -match ' ') {
            # quote arguments with spaces
            $args[$i] = "'$($args[$i])'"
        }
    }
    # run sudo command with resolved commands
    & /usr/bin/env sudo $params pwsh -NoProfile -NonInteractive -Command "$args"
}

Set-Alias -Name sps -Value Invoke-SudoPS

<#
.SYNOPSIS
Fix executable bit based on shebang presence.
.DESCRIPTION
Process specified directory, looking for bash and powershell scripts, and sets executable bit based on shebang presence.
#>
function Invoke-FixExecutableBit {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullorEmpty()]
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "`e[1;4m{0}`e[22;24m is not valid path")]
        [string]$Path = '.'
    )

    begin {
        # script extensions
        [string[]]$extFilter = @('.ps1', '.sh')
    }

    process {
        # *adding executable bit in files with shebang
        (Get-ChildItem $Path -File -Recurse -Force).Where({
                $_.DirectoryName -notmatch '/\.git\b' `
                    -and ($_.Extension -in $extFilter -or -not $_.Extension) `
                    -and $_.UnixMode -notmatch '^-rwx' `
                    -and (Get-Content $_ -Head 1 | Select-String '^#!' -Quiet)
            }
        ).ForEach({
                Write-Host $_.FullName -ForegroundColor Green
                chmod +x $_.FullName
            }
        )

        # *removing executable bit from files without shebang
        (Get-ChildItem $Path -File -Recurse -Force).Where({
                $_.DirectoryName -notmatch '/\.git\b' `
                    -and ($_.Extension -in $extFilter -or -not $_.Extension) `
                    -and $_.UnixMode -match '^-rwx' `
                    -and (Get-Content $_ -Head 1 | Select-String '^#!' -NotMatch -Quiet)
            }
        ).ForEach({
                Write-Host $_.FullName
                chmod -x $_.FullName
            }
        )
    }
}

Set-Alias -Name feb -Value Invoke-FixExecutableBit

<#
.SYNOPSIS
Remove Windows paths from PATH environment variable in WSL to speed up file search.
#>
function Remove-WindowsPathInWSL {
    [Environment]::SetEnvironmentVariable(
        'PATH',
        [string]::Join(
            [IO.Path]::PathSeparator,
            ($env:PATH.Split([IO.Path]::PathSeparator) -notmatch '^/mnt/c' | Select-Object -Unique)
        )
    )
}

Set-Alias -Name wslp -Value Remove-WindowsPathInWSL
