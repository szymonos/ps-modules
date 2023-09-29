<#
.SYNOPSIS
Returns system information from /etc/os-release.
#>
function Get-SysInfo {
    # get CPU properties
    $cpu = Get-CimInstance -ClassName Win32_Processor
    # get system properties
    $gcim = Get-CimInstance -ClassName Win32_OperatingSystem
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\'
    # calculate memory usage
    $memTotal = $gcim.TotalVisibleMemorySize / 1MB
    $memUsed = ($gcim.TotalVisibleMemorySize - $gcim.FreePhysicalMemory) / 1MB

    # build system properties
    $esc = [char]27
    $sysProp = [string]::Join("`n",
        "$esc[1;32mUserHost       :$esc[0m $esc[1;34m$env:USERNAME$esc[0m@$esc[1;34m$env:COMPUTERNAME$esc[0m",
        "$esc[1;32mOS             :$esc[0m $esc[1;37m$($gcim.Caption.Replace('Microsoft ', '')) ($($cv.DisplayVersion)) $($gcim.OSArchitecture)$esc[0m",
        "$esc[1;32mKernel         :$esc[0m $($gcim.Version).$($cv.UBR)",
        "$esc[1;32mInstalled      :$esc[0m $($gcim.InstallDate.ToString('yyyy-MM-d'))",
        "$esc[1;32mUptime         :$esc[0m $(Format-Duration ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime))",
        "$esc[1;32mShell          :$esc[0m PowerShell $($PSVersionTable.PSVersion)",
        "$esc[1;32mCPU            :$esc[0m $($cpu.Name) ($($cpu.NumberOfCores)/$($cpu.NumberOfLogicalProcessors))",
        "$esc[1;32mMemory         :$esc[0m $('{0:n2} GiB / {1:n2} GiB ({2:p0})' -f $memUsed, $memTotal, ($memUsed / $memTotal))",
        "$esc[1;32mRegisteredUser :$esc[0m $($gcim.RegisteredUser)"
    )

    return $sysProp
}

New-Alias -Name gsi -Value Get-SysInfo

<#
.SYNOPSIS
Print timespan in human readable format.

.PARAMETER TimeSpan
Timespan to be formatted as human redable duration.
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
.PARAMETER Command
Script block of commands to execute.
.PARAMETER MaxRetries
Maximum number of retries to rerun the script block.
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
            Invoke-Command -ScriptBlock $Command
            $exit = $true
        } catch [System.IO.IOException] {
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
Create a new file.
#>
function New-File {
    New-Item @args -ItemType File | Out-Null
}

Set-Alias -Name touch -Value New-File

<#
.SYNOPSIS
Check if PowerShell runs elevated.
#>
function Test-IsAdmin {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]$currentIdentity
    $admin = [System.Security.Principal.WindowsBuiltInRole]'Administrator'

    return $principal.IsInRole($admin)
}

<#
.SYNOPSIS
Refresh path environment variable for process scope.
#>
function Update-SessionEnvironmentPath {
    # instantiate a HashSet to store unique paths
    $auxHashSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    # get Path env variable from all scopes and build unique set
    foreach ($scope in @('Machine', 'User', 'Process')) {
        [Environment]::GetEnvironmentVariable('Path', $scope).Split(';').Where({ $_ }).ForEach({
                $auxHashSet.Add($_) | Out-Null
            }
        )
    }

    # build a path string from the HashSet
    $pathStr = [string]::Join([System.IO.Path]::PathSeparator, $auxHashSet)
    # set the Path environment variable in the current process scope
    [System.Environment]::SetEnvironmentVariable('Path', $pathStr, 'Process')
}

Set-Alias -Name refreshenvpath -Value Update-SessionEnvironmentPath
