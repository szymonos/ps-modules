<#
.SYNOPSIS
Create PowerShell module manifest.
.PARAMETER Module
Module name.

.EXAMPLE
$Module = 'do-test'
./module_create.ps1 -m $Module
#>
[CmdletBinding()]
param (
    [Alias('m')]
    [Parameter(Mandatory)]
    [string]$Module
)

if (-not (Test-Path -Path "./modules/$Module")) {
    New-Item -Path "./modules/$Module" -Force -ItemType Directory | Out-Null
}

New-ModuleManifest -Path "modules/$Module/$Module.psd1"
