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
./module_manage.ps1 $Module -CleanUp
./module_manage.ps1 $Module -CleanUp -RemoveRequirements
# *delete module
./module_manage.ps1 $Module -Delete
# *scaffold module manifest
./module_manage.ps1 -Module 'do-test' -Create
#>
[CmdletBinding(DefaultParameterSetName = 'Install')]
param (
    [Parameter(Mandatory, Position = 0)]
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
    # source paths
    $srcModulePath = Join-Path 'modules' -ChildPath $Module
    $srcModuleManifest = Join-Path $srcModulePath -ChildPath "$Module.psd1"
    # set location to workspace folder
    if ($PWD.Path -ne $PSScriptRoot) {
        $startWorkingDirectory = $PWD.Path
        Write-Verbose "Correcting script working directory to '$PSScriptRoot'."
        Set-Location $PSScriptRoot
    }
}

process {
    switch -Regex ($PsCmdlet.ParameterSetName) {
        'Install|Delete' {
            # check if module exists
            if (-not (Test-Path $srcModuleManifest)) {
                Write-Warning "Module doesn't exist ($Module)."
                exit
            }
            # *calculate destination path
            $isAdmin = if ($IsWindows) {
                ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
            } else {
                ((id -u) -eq 0) ? $true : $false
            }
            $psModPathSplit = $env:PSModulePath.Split([IO.Path]::PathSeparator)
            $psModPath = $isAdmin ? $psModPathSplit[1] : $psModPathSplit[0]
            $dstModulePath = Join-Path $psModPath -ChildPath $Module
        }

        'Install' {
            # *install modules
            $manifest = Test-ModuleManifest $srcModuleManifest
            $installPath = Join-Path $dstModulePath -ChildPath $manifest.Version.ToString()

            # create/cleanup destination directory
            if (Test-Path $dstModulePath -PathType Container) {
                # clean-up old module versions
                if ($CleanUp) {
                    Remove-Item $dstModulePath -Recurse -Force
                } else {
                    Remove-Item $installPath -Recurse -Force
                }
            }
            New-Item -ItemType Directory -Force -Path $installPath | Out-Null

            # copy module files
            Copy-Item -Path (Join-Path $manifest.ModuleBase -ChildPath '*') -Destination $installPath -Recurse

            # remove requirements from module manifest to speed up module loading time
            if ($RemoveRequirements) {
                $dstModuleManifest = Join-Path $installPath -ChildPath "$Module.psd1"
            (Get-Content $dstModuleManifest -Raw) -replace '(?s)RequiredModules.*?\)\n' | Set-Content $dstModuleManifest
            }
            continue
        }

        'Delete' {
            # *delete modules
            Remove-Item -Path $dstModulePath -Force -Recurse -ErrorAction SilentlyContinue
            continue
        }

        'Create' {
            # *scaffold new module manifest
            if (-not (Test-Path -Path $srcModulePath -PathType Container)) {
                New-Item -Path $srcModulePath -ItemType Directory | Out-Null
            }
            New-ModuleManifest -Path $srcModuleManifest
            continue
        }
    }
}

end {
    # revert to starting work directory
    Set-Location $startWorkingDirectory
}
