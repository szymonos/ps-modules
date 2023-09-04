#!/usr/bin/pwsh -nop
#Requires -Version 7.0
#Requires -Module Microsoft.PowerShell.PSResourceGet
<#
.SYNOPSIS
Manage PowerShell modules.
.DESCRIPTION
Script for installing, removing or scaffolding new PowerShell modules.
If script is running elevated, it automatically install/delete module in AllUsers scope.
.PARAMETER Module
Module name.
.PARAMETER CleanUp
Switch, whether to clean up module previous versions in destination folder.
.PARAMETER RemoveRequirements
Switch, whether to remove requirements from the manifest file to speed up module loading.
.PARAMETER Force
Force reinstalling module even if current version is already installed.
.PARAMETER Delete
Switch, whether to delete an existing module.
.PARAMETER Create
Switch, whether to scaffold a new module manifest.

.EXAMPLE
# *module
$Module = 'aliases-git'
$Module = 'aliases-kubectl'
$Module = 'do-az'
$Module = 'do-common'
$Module = 'do-linux'
$Module = 'do-win'
# *install
./module_manage.ps1 $Module -CleanUp -Verbose
./module_manage.ps1 $Module -CleanUp -Verbose -Scope CurrentUser
./module_manage.ps1 $Module -CleanUp -Verbose -Force
./module_manage.ps1 $Module -CleanUp -RemoveRequirements -Verbose
@('aliases-git', 'aliases-kubectl') | ./module_manage.ps1 -CleanUp -Verbose
# *delete module
./module_manage.ps1 $Module -Delete -Verbose
# *scaffold module manifest
./module_manage.ps1 -Module 'do-test' -Create -Verbose
#>
[CmdletBinding(DefaultParameterSetName = 'Install')]
param (
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [string]$Module,

    [Parameter(ParameterSetName = 'Install')]
    [switch]$CleanUp,

    [Parameter(ParameterSetName = 'Install')]
    [switch]$RemoveRequirements,

    [Parameter(ParameterSetName = 'Install')]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope,

    [Parameter(ParameterSetName = 'Install')]
    [switch]$Force,

    [Parameter(ParameterSetName = 'Delete')]
    [switch]$Delete,

    [Parameter(ParameterSetName = 'Create')]
    [switch]$Create
)

begin {
    $ErrorActionPreference = 'Stop'
    # set location to workspace folder
    Push-Location $PSScriptRoot
}

process {
    switch -Regex ($PsCmdlet.ParameterSetName) {
        'Install|Create' {
            # calculate source paths
            $srcModulePath = [IO.Path]::Combine('modules', $Module)
            $srcModuleManifest = [IO.Path]::Combine($srcModulePath, "$Module.psd1")
        }

        Install {
            # *install modules
            # calculate destination path determined on the Scope
            $isAdmin = if ($IsWindows) {
                    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
            } else {
                    ((id -u) -eq 0) ? $true : $false
            }
            if ($Scope) {
                if (-not $isAdmin -and $Scope -eq 'AllUsers') {
                    Write-Error "Cannot install `"$Module`" module to the AllUsers scope. Run the script as Admin."
                }
            } else {
                $Scope = $isAdmin ? 'AllUsers' : 'CurrentUser'
            }
            $psModPathSplit = $env:PSModulePath.Split([IO.Path]::PathSeparator)
            $psModPath = switch ($Scope) {
                AllUsers {
                    $psModPathSplit[1]
                }
                CurrentUser {
                    $psModPathSplit[0]
                }
            }
            $dstModulePath = [IO.Path]::Combine($psModPath, $Module)
            # check if module exists
            if (-not (Test-Path $srcModuleManifest)) {
                Write-Warning "Module doesn't exist ($Module)."
                exit
            }
            # get module manifest
            try {
                $manifest = Test-ModuleManifest $srcModuleManifest -ErrorAction Stop
            } catch [IO.DirectoryNotFoundException] {
                # install missing required modules
                $manifest = Test-ModuleManifest $srcModuleManifest -ErrorAction SilentlyContinue
                foreach ($mod in $manifest.RequiredModules.Name) {
                    if (-not (Get-Module -ListAvailable $mod)) {
                        Install-PSResource $mod -WarningAction SilentlyContinue
                    }
                }
            } catch {
                Write-Verbose $_.Exception.GetType().FullName
                Write-Error $_
                break
            }
            $installPath = [IO.Path]::Combine($dstModulePath, $manifest.Version)
            # create/cleanup destination directory
            if (-not $Force -and ($manifest.Version -eq (Get-Module $Module -ListAvailable).Version)) {
                Write-Verbose "Current module version already installed in the $Scope scope ($Module v$($manifest.Version))."
            } else {
                # clean-up old module versions
                if ($CleanUp -and (Test-Path $dstModulePath -PathType Container)) {
                    Remove-Item ([IO.Path]::Combine($dstModulePath, '*')) -Recurse -Force
                }
                New-Item -ItemType Directory -Force -Path $installPath | Out-Null
                # copy module files
                Copy-Item -Path ([IO.Path]::Combine($manifest.ModuleBase, '*')) -Destination $installPath -Recurse
                # remove requirements from module manifest to speed up module loading time
                if ($RemoveRequirements) {
                    $dstModuleManifest = [IO.Path]::Combine($installPath, "$Module.psd1")
                    [IO.File]::WriteAllText($dstModuleManifest, [IO.File]::ReadAllText($dstModuleManifest) -replace '(?s)RequiredModules.*?\)\n')
                }
                Write-Verbose "Module $Module v$($manifest.Version) installed in the $Scope scope."
            }
            continue
        }

        Create {
            # *scaffold new module manifest
            if (-not (Test-Path -Path $srcModulePath -PathType Container)) {
                New-Item -Path $srcModulePath -ItemType Directory | Out-Null
            }
            New-ModuleManifest -Path $srcModuleManifest
            Write-Verbose "Created module manifest in $($srcModuleManifest.Replace($HOME, '~'))"
            continue
        }

        Delete {
            # *delete modules
            $modules = Get-Module $Module -ListAvailable
            if ($modules) {
                Write-Verbose "uninstalling module ($Module)"
                foreach ($mod in $modules) {
                    Write-Verbose " - $($mod.Version)"
                    Remove-Item -Path $mod.ModuleBase -Force -Recurse -ErrorAction SilentlyContinue
                }
            } else {
                Write-Verbose "Module do not exists ($Module)."
            }
            continue
        }
    }
}

end {
    Pop-Location
}
