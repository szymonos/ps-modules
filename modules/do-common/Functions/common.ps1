<#
.SYNOPSIS
Convert text from Base64 string.
.PARAMETER InputObject
Base64 encoded string to be converted.
#>
function ConvertFrom-Base64 {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputObject
    )

    process {
        $bytes = [System.Convert]::FromBase64String($InputObject)
        [System.Text.Encoding]::UTF8.GetString($bytes)
    }
}

<#
.SYNOPSIS
Convert text to Base64 string.
.PARAMETER InputObject
Text to be converted to Base64 string.
#>
function ConvertTo-Base64 {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputObject
    )

    process {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject)
        [System.Convert]::ToBase64String($bytes)
    }
}

<#
.SYNOPSIS
Convert all files in a directory to UTF8 and change EOLs from CRLF to LF.
.PARAMETER $Path
Directory to convert all files from.
#>
function ConvertTo-UTF8LF {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$Path = '.'
    )

    begin {
        $encoding = [System.Text.UTF8Encoding]::new($false)
        $fileCnt = 0
    }

    process {
        # get list of files to process, excluding .git subdirectory
        $files = (Get-ChildItem $Path -File -Force -Recurse).Where({ $_.DirectoryName -notmatch '(/|\\)\.git\b' })
        # convert files
        foreach ($file in $files) {
            $content = [System.IO.File]::ReadAllText($file).Replace("`r`n", "`n")
            [System.IO.File]::WriteAllText($file, $content, $encoding)
        }
        $fileCnt += $files.Count
    }

    end {
        Write-Host "Converted $fileCnt file(s)."
    }
}

<#
.SYNOPSIS
Get item index(es) or value(s) of the provided array from selection menu.
.PARAMETER Array
Array of strings to get the selection menu.
.PARAMETER Message
Optional menu header to display.
.PARAMETER Value
Flag to return value(s) instead of index(es).
.PARAMETER List
Flag to choose from selection list instead of single value.
#>
function Get-ArrayIndexMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object[]]$Array,

        [Parameter(Position = 1)]
        [string]$Message,

        [switch]$Value,

        [switch]$List
    )
    begin {
        # instantiate generic list to store the input array
        $lst = [System.Collections.Generic.List[object]]::new()
    }

    process {
        # determine if the input array has multiple properties
        if (-not $arrayType) {
            $arrayType = ($Array | Select-Object * | Get-Member -MemberType NoteProperty).Count -gt 1 ? 'object' : 'string'
        }
        # add input array items to the generic list
        $Array.ForEach({ $lst.Add($_) })
    }

    end {
        # create selection menu
        $menu = switch ($arrayType) {
            object {
                $i = 0
                $lst `
                | Select-Object @{ N = '#'; E = { $lst.Count -eq 1 ? 0 : $lst.IndexOf($_) } }, @{ N = ' '; E = { '-' } }, * `
                | Format-Table -AutoSize `
                | Out-String -Stream `
                | ForEach-Object { $i -lt 3 ? "`e[1;92m$_`e[0m" : $_; $i++ } `
                | Out-String
                continue
            }
            string {
                $lst.ToArray().ForEach({ [PSCustomObject]@{ '#' = $lst.IndexOf($_); ' ' = '-'; 'V' = $_ } }) `
                | Format-Table -AutoSize -HideTableHeaders `
                | Out-String
                continue
            }
        }

        # create prompt message
        if (-not $Message) {
            $Message = $List ? 'Enter comma/space separated selection list' : 'Enter selection'
        }
        $msg = "`n`e[4m$Message`e[0m:`n$menu"

        # read and validate input
        do {
            [array]$inputArray = (Read-Host -Prompt $msg).Split([char[]]@(' ', ','), [StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Unique
        } while (($inputArray.ForEach({ $_ -in 0..($lst.Count - 1) }) -contains $false) -or (-not $List -and $inputArray.Count -gt 1) -or (-not $inputArray))

        # return result
        return $Value ? $inputArray.ForEach{ $lst[$_] } : $inputArray
    }
}

<#
.SYNOPSIS
Get the aliases for any cmdlet.
#>
function Get-CmdletAlias {
    [CmdletBinding()]
    param (
        [string]$CmdletName
    )

    Get-Alias | `
        Where-Object -FilterScript { $_.Definition -match $CmdletName } | `
        Sort-Object -Property Definition, Name | `
        Select-Object -Property Definition, Name
}

Set-Alias -Name alias -Value Get-CmdletAlias

<#
.SYNOPSIS
Parse semantic version and return Major, Minor, Patch numbers.
#>
function Get-SemanticVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ [regex]::IsMatch($_, '^v?\d+\.\d+\.\d+$') }, ErrorMessage = "`e[1;4m{0}`e[22;24m is not valid version")]
        [string]$Version
    )

    $major, $minor, $patch = [int[]]$Version.Replace('v', '').Split('.')

    return [PSCustomObject]@{
        Major = $major
        Minor = $minor
        Patch = $patch
    }
}

<#
.SYNOPSIS
Print timespan in human readable format.
#>
function Format-Duration {
    [CmdletBinding()]
    param (
        [timespan]$TimeSpan
    )

    switch ($TimeSpan) {
        { $_.TotalMilliseconds -gt 0 -and $_.TotalMilliseconds -lt 10 } { '{0:N2}ms' -f $_.TotalMilliseconds; continue }
        { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { '{0:N1}ms' -f $_.TotalMilliseconds; continue }
        { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { '{0:N0}ms' -f $_.TotalMilliseconds; continue }
        { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { '{0:N3}s' -f $_.TotalSeconds; continue }
        { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { '{0:N2}s' -f $_.TotalSeconds; continue }
        { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff'); continue }
        { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss'); continue }
        { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))"; continue }
        Default { '0ms' }
    }
}

<#
.SYNOPSIS
Retry executing command if fails on HttpRequestException.
.PARAMETER Script
Script block of commands to execute.
#>
function Invoke-CommandRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The command to be invoked.')]
        [scriptblock]$Command,

        [Parameter(HelpMessage = 'The number of retries the command should be invoked.')]
        [int]$MaxRetries = 10
    )

    Set-Variable -Name retryCount -Value 0
    do {
        try {
            Invoke-Command -ScriptBlock $Command -ErrorAction Stop
            $exit = $true
        } catch [System.Net.Http.HttpRequestException] {
            if ($_.Exception.TargetSite.Name -eq 'MoveNext') {
                if ($_.ErrorDetails) {
                    Write-Verbose $_.ErrorDetails.Message
                } else {
                    Write-Verbose $_.Exception.Message
                }
                Write-Host "`nRetrying..."
            } else {
                Write-Verbose $_.Exception.GetType().FullName
                Write-Error $_
            }
        } catch [System.AggregateException] {
            if ($_.Exception.InnerException.GetType().Name -eq 'HttpRequestException') {
                Write-Verbose $_.Exception.InnerException.Message
                Write-Host "`nRetrying..."
            } else {
                Write-Verbose $_.Exception.InnerException.GetType().FullName
                Write-Error $_
            }
        } catch {
            Write-Verbose $_.Exception.GetType().FullName
            Write-Error $_
        }
        $retryCount++
        if ($retryCount -eq $MaxRetries) {
            $exit = $true
        }
    } until ($exit)
}

<#
.SYNOPSIS
Save examples from PowerShell scripts to the gitignored console folder.
.PARAMETER Path
Path to the script to save the examples from.
By default the script searches for all ps1 files in the current directory.
.PARAMETER FolderFromBase
Save example script in the folder of the base script.
.EXAMPLE
# ~save example scripts for all PowerShell scripts in the current directory
Invoke-ExampleScriptSave
Invoke-ExampleScriptSave -FolderFromBase
# ~save example script for the specified PowerShell script(s)
$Path = 'folder/script*.ps1'
Invoke-ExampleScriptSave $Path
Invoke-ExampleScriptSave $Path -FolderFromBase
#>
function Invoke-ExampleScriptSave {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path = './*.ps1',

        [switch]$FolderFromBase
    )

    begin {
        $ErrorActionPreference = 'Stop'
        # instantiate generic list to store example script(s) name(s)
        $lst = [Collections.Generic.List[string]]::new()
        # determine if there are PowerShell scripts with examples in the current directory
        try {
            $psScripts = Select-String '^\.EXAMPLE' $Path
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Warning "Cannot find path because it does not exist ($Path)."
            return
        } catch {
            Write-Verbose $_.Exception.GetType().FullName
            Write-Error $_
        }
        if ($psScripts) {
            # get git root
            $gitRoot = git rev-parse --show-toplevel
            # add the console folder to .gitignored if necessary
            if (-not (Select-String '\bconsole\b' "$gitRoot/.gitignore" -Quiet)) {
                [IO.File]::AppendAllLines("$gitRoot/.gitignore", [string[]]'/console/')
            }
            # determine and create example folder to put example scripts in
            $exampleDir = if ($FolderFromBase) {
                [IO.Path]::Combine($gitRoot, 'console', (Get-Item $psScripts[0].Path).Directory.Name)
            } else {
                [IO.Path]::Combine($gitRoot, 'console')
            }
            if (-not (Test-Path $exampleDir -PathType Container)) {
                New-Item $exampleDir -ItemType Directory | Out-Null
            }
        } else {
            return
        }
    }

    process {
        foreach ($script in $psScripts) {
            # check if the script has examples
            $content = [IO.File]::ReadAllText($script.Path)
            $example = [regex]::Matches($content, '(?s)(?<=\n\.EXAMPLE\n).*?(?=(\n#>|\n\.[A-Z]))').Value
            if ($example) {
                # get parameters description
                $param = [regex]::Matches($content, '(?s)(?<=\n)\.PARAMETER \w+\n(.*?)(?=\n(\n\.[A-Z]+\n|#>))').Value
                # calculate example file path
                $exampleFile = [IO.Path]::Combine($exampleDir, $script.Filename)
                # save parameters and examples to the example script
                [IO.File]::WriteAllLines($exampleFile, "$($param ? "<#`n$param`n#>`n`n" : '')$example")
                # add example script path to the list
                $lst.Add([IO.Path]::GetRelativePath($gitRoot, $exampleFile))
            }
        }
    }

    end {
        return $lst.ToArray().ForEach({ Write-Host "$_" })
    }
}

Set-Alias -Name egsave -Value Invoke-ExampleScriptSave

<#
.SYNOPSIS
Generate a random string.
#>
function New-Password {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Int]$Size = 8,

        [Char[]]$Complexity = 'ULNS',

        [Char[]]$Exclude
    )
    $AllTokens = @();
    $Chars = @();
    $TokenSets = @{
        UpperCase = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        LowerCase = [Char[]]'abcdefghijklmnopqrstuvwxyz'
        Numbers   = [Char[]]'0123456789'
        Symbols   = [Char[]]'!#%&*+-<>@^_|~'
    }
    $TokenSets.Keys | Where-Object { $Complexity -Contains $_[0] } | ForEach-Object {
        $TokenSet = $TokenSets.$_ | Where-Object { $Exclude -cNotContains $_ } | ForEach-Object { $_ }
        if ($_[0] -cle 'Z') {
            $Chars += $TokenSet | Get-Random
        }
        $AllTokens += $TokenSet
    }
    while ($Chars.Count -lt $Size) {
        $Chars += $AllTokens | Get-Random
    } -join ($Chars | Sort-Object { Get-Random })
}

<#
.SYNOPSIS
Show specified properties of the object.

.PARAMETER Object
Object to be showed.
.PARAMETER TypeName
Array of properties system types to be shown (System.String, System.Datetime, ...).
.PARAMETER MemberType
Array of properties member types to be shown (Property, AliasProperty, ...).
.PARAMETER Strip
Switch whether to strip properties without value.
#>
function Show-Object {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[object]])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [object]$Object,

        [string[]]$TypeName,

        [string[]]$MemberType,

        [switch]$Strip
    )

    process {
        [string[]]$prop = $Object.PSObject.Properties.Where({
                ($TypeName ? $_.TypeNameOfValue -in $TypeName : $true) -and
                ($MemberType ? $_.MemberType -in $MemberType : $true) -and
                ($Strip ? -not [string]::IsNullOrEmpty($_.Value) : $true)
            }
        ).Name
        $Object | Select-Object $prop
    }
}

<#
.SYNOPSIS
Check if PowerShell runs elevated.
#>
function Test-IsAdmin {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    process {
        $isAdmin = if ($IsWindows) {
            ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
        } else {
            ((id -u) -eq 0) ? $true : $false
        }
    }

    end {
        return $isAdmin
    }
}
