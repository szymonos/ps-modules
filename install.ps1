<#
.SYNOPSIS
Install the module.
.PARAMETER CleanUp
If set, script will remove all existing module versions.

.EXAMPLE
./install.ps1
./install.ps1 -CleanUp
#>
[CmdletBinding()]
param (
    [Alias('c')]
    [switch]$CleanUp
)
# get module path in user context
$installPath = [IO.Path]::Join(
    $env:PSModulePath.Split("$($IsWindows ? ';' : ':')")[0],
    'ps-szymonos',
    (Test-ModuleManifest 'src/ps-szymonos.psd1').Version.ToString()
)

# create/cleanup destination directory
if (Test-Path $installPath) {
    if ($CleanUp) {
        Remove-Item "$(Split-Path $installPath)/*" -Recurse -Force
    } else {
        Remove-Item $installPath -Recurse -Force
    }
}
New-Item -ItemType Directory -Force -Path $installPath | Out-Null

# copy module files
Copy-Item -Path "$PSScriptRoot/src/*" -Destination $installPath -Recurse
