<#
.SYNOPSIS
Install the module.
.PARAMETER Module
Specify module to install.
.PARAMETER CleanUp
Remove all existing module versions in installed module directory.
.PARAMETER RemoveRequirements
Remove RequiredModules from module manifest to speed up loading time.

.EXAMPLE
./module_install.ps1 -CleanUp -Module 'do-common'
./module_install.ps1 -CleanUp -Module 'do-win'
./module_install.ps1 -CleanUp -Module 'do-az' -RemoveRequirements
#>
[CmdletBinding()]
param (
    [Alias('m')]
    [Parameter(Mandatory)]
    [ValidateSet('do-common', 'do-az', 'do-win')]
    [string]$Module,

    [Alias('c')]
    [switch]$CleanUp,

    [Alias('r')]
    [switch]$RemoveRequirements
)

# get module path in user context
$manifest = Test-ModuleManifest "modules/$Module/$Module.psd1"
$modulePath = [IO.Path]::Join(
    $env:PSModulePath.Split("$($IsWindows ? ';' : ':')")[0],
    $Module
)
$installPath = [IO.Path]::Join(
    $modulePath,
    $manifest.Version.ToString()
)

# create/cleanup destination directory
if (Test-Path $modulePath) {
    # clean-up old module versions
    if ($CleanUp) {
        Remove-Item "$modulePath/*" -Recurse -Force
    } else {
        Remove-Item $installPath -Recurse -Force
    }
}
New-Item -ItemType Directory -Force -Path $installPath | Out-Null

# copy module files
Copy-Item -Path "$PSScriptRoot/modules/$Module/*" -Destination $installPath -Recurse

# remove requirements from module manifest to speed up module loading time
if ($RemoveRequirements) {
    $manifest = "$installPath/$Module.psd1"
    (Get-Content $manifest -Raw) -replace '(?s)RequiredModules.*?\)\n' | Set-Content $manifest
}
