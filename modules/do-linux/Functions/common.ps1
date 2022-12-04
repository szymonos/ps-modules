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
