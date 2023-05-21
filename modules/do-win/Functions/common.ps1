<#
.SYNOPSIS
Get the source directory for command.
#>
function Get-CommandSource {
    (Get-Command @args -ErrorAction SilentlyContinue).Where({ $_.Source }).Source
}

Set-Alias -Name which -Value Get-CommandSource

<#
.SYNOPSIS
Get summary size of files inside folders.
#>
function Get-DiskUsage {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [string]$Path = '.',

        [switch]$HumanReadable,

        [switch]$Recurse,

        [switch]$All,

        [ValidateSet('size', 'count', 'name')]
        [string]$Sort
    )

    begin {
        # filter for size formatting
        filter formatSize {
            switch ($_) {
                { $_ -ge 1KB -and $_ -lt 1MB } { '{0:0.0}K' -f ($_ / 1KB); continue }
                { $_ -ge 1MB -and $_ -lt 1GB } { '{0:0.0}M' -f ($_ / 1MB); continue }
                { $_ -ge 1GB -and $_ -lt 1TB } { '{0:0.0}G' -f ($_ / 1GB); continue }
                { $_ -ge 1TB } { '{0:0.0}T' -f ($_ / 1TB) }
                Default { "$_.0B" }
            }
        }

        # initialize empty collections
        $dirs = [Collections.Generic.List[PSObject]]::new()
        if ($Sort) {
            $result = [Collections.Generic.List[PSObject]]::new()
        }

        # IO enumeration options
        $enumDirs = [IO.EnumerationOptions]::new()
        $enumDirs.RecurseSubdirectories = $Recurse
        $enumFiles = [IO.EnumerationOptions]::new()
        $enumFiles.RecurseSubdirectories = !$Recurse
        # determine if to skip hidden and system objects
        $enumDirs.AttributesToSkip = $enumFiles.AttributesToSkip = ($All ? 0 : 6)
    }

    process {
        $startPath = Get-Item $Path
        $startPath.GetDirectories('*', $enumDirs).ForEach({ $dirs.Add($_) })
        if ($Recurse) {
            $dirs.Add($startPath)
        }
        foreach ($dir in $dirs) {
            $items = $dir.GetFiles('*', $enumFiles)
            $size = 0 + ($items | Measure-Object -Property Length -Sum).Sum
            $cnt = ($items | Measure-Object).Count
            $relPath = [IO.Path]::GetRelativePath($startPath.FullName, $dir.FullName)
            if ($Sort) {
                $result.Add([PSCustomObject]@{
                        Size  = $size
                        Count = $cnt
                        Name  = $relPath
                    })
            } else {
                if ($HumanReadable) {
                    $size = $size | formatSize
                    "$(' ' * (7 - $size.Length))$size   $(' ' * (8 - $cnt.ToString().Length))$cnt   $relPath"
                } else {
                    "$(' ' * (16 - $size.ToString().Length))$size   $(' ' * (8 - $cnt.ToString().Length))$cnt   $relPath"
                }
            }
        }

        if ($Sort) {
            $result | Sort-Object -Property $Sort | `
                Format-Table -HideTableHeaders @{Name = 'Size'; Expression = { $HumanReadable ? ($_.Size | formatSize) : ($_.Size) }; Align = 'Right' }, Count, Name
        }
    }
}

Set-Alias -Name du -Value Get-DiskUsage

<#
.SYNOPSIS
Returns system information from /etc/os-release.
#>
function Get-SysInfo {
    # get system properties
    $gcim = Get-CimInstance -ClassName Win32_OperatingSystem
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\'
    # calculate memory usage
    $memTotal = $gcim.TotalVisibleMemorySize / 1MB
    $memUsed = ($gcim.TotalVisibleMemorySize - $gcim.FreePhysicalMemory) / 1MB
    # get CPU info
    $cpu = Get-ChildItem -Path HKLM:HARDWARE\DESCRIPTION\System\CentralProcessor

    # build system properties
    $sysProp = [ordered]@{
        UserHost       = "`e[1;34m$env:USERNAME`e[0m@`e[1;34m$env:COMPUTERNAME`e[0m"
        OS             = "$($gcim.Caption.Replace('Microsoft ', '')) ($($cv.DisplayVersion)) $($gcim.OSArchitecture)"
        Kernel         = "$($gcim.Version).$($cv.UBR)"
        Installed      = $gcim.InstallDate.ToString('yyyy-MM-d')
        Uptime         = "$(Get-Uptime)"
        Shell          = "PowerShell $($PSVersionTable.PSVersion)"
        CPU            = "$($cpu[0].GetValue('ProcessorNameString')) ($($cpu.Count))"
        Memory         = '{0:n2} GiB / {1:n2} GiB ({2:p0})' -f $memUsed, $memTotal, ($memUsed / $memTotal)
        RegisteredUser = $gcim.RegisteredUser
    }

    return [PSCustomObject]$sysProp
}

New-Alias -Name gsi -Value Get-SysInfo

<#
.SYNOPSIS
Create a new file.
#>
function New-File {
    New-Item @args -ItemType File | Out-Null
}

Set-Alias -Name touch -Value New-File
