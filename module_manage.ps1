#!/usr/bin/env -S pwsh -nop
#Requires -Version 7.0
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
.PARAMETER Delete
Switch, whether to delete an existing module.
.PARAMETER Create
Switch, whether to scaffold a new module manifest.

.EXAMPLE
# *module
$Module = 'do-az'
$Module = 'do-common'
$Module = 'do-linux'
$Module = 'do-win'
# *install
./module_manage.ps1 $Module -CleanUp -Verbose
./module_manage.ps1 $Module -CleanUp -RemoveRequirements -Verbose
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
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser',

    [Parameter(ParameterSetName = 'Install')]
    [switch]$CleanUp,

    [Parameter(ParameterSetName = 'Install')]
    [switch]$RemoveRequirements,

    [Parameter(ParameterSetName = 'Delete')]
    [switch]$Delete,

    [Parameter(ParameterSetName = 'Create')]
    [switch]$Create
)

begin {
    # set location to workspace folder
    if ($PSScriptRoot -ne $PWD.Path) {
        $startWorkingDirectory = $PWD
        Write-Verbose "Setting working directory to '$($PSScriptRoot.Replace($HOME, '~'))'."
        Set-Location $PSScriptRoot
    }
}

process {
    switch -Regex ($PsCmdlet.ParameterSetName) {
        'Install|Delete|Create' {
            # calculate source paths
            $srcModulePath = [IO.Path]::Combine('modules', $Module)
            $srcModuleManifest = [IO.Path]::Combine($srcModulePath, "$Module.psd1")
        }

        'Install|Delete' {
            # check if module exists
            if (-not (Test-Path $srcModuleManifest)) {
                Write-Warning "Module doesn't exist ($Module)."
                exit
            }
            # calculate destination path
            $isAdmin = if ($IsWindows) {
                ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
            } else {
                ((id -u) -eq 0) ? $true : $false
            }
            $psModPathSplit = $env:PSModulePath.Split([IO.Path]::PathSeparator)
            $psModPath = $isAdmin ? $psModPathSplit[1] : $psModPathSplit[0]
            $dstModulePath = [IO.Path]::Combine($psModPath, $Module)
        }

        'Install' {
            # *install modules
            try {
                $manifest = Test-ModuleManifest $srcModuleManifest -ErrorAction Stop
                $installPath = [IO.Path]::Combine($dstModulePath, $manifest.Version)
                # create/cleanup destination directory
                if (Test-Path $installPath -PathType Container) {
                    Write-Verbose "Current module version already installed ($Module v$($manifest.Version))."
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
                    Write-Verbose "Module installed in $($dstModulePath.Replace($HOME, '~'))"
                }
            } catch {
                Write-Warning $_
            }
            continue
        }

        'Delete' {
            # *delete modules
            if (Test-Path $dstModulePath) {
                Remove-Item -Path $dstModulePath -Force -Recurse -ErrorAction SilentlyContinue
                Write-Verbose "Deleted module location $($dstModulePath.Replace($HOME, '~'))"
            } else {
                Write-Verbose "Module do not exists in location $($dstModulePath.Replace($HOME, '~'))"
            }
            continue
        }

        'Create' {
            # *scaffold new module manifest
            if (-not (Test-Path -Path $srcModulePath -PathType Container)) {
                New-Item -Path $srcModulePath -ItemType Directory | Out-Null
            }
            New-ModuleManifest -Path $srcModuleManifest
            Write-Verbose "Created module manifest in $($srcModuleManifest.Replace($HOME, '~'))"
            continue
        }
    }
}

end {
    if ($startWorkingDirectory) {
        Set-Location $startWorkingDirectory
    }
}
