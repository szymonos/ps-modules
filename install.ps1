<#
.SYNOPSIS
Install the module.
.EXAMPLE
./install.ps1
#>
# get module path in user context
$installPath = Join-Path $env:PSModulePath.Split("$($IsWindows ? ';' : ':')")[0] -ChildPath 'ps-szymonos'

# create/cleanup destination directory
if (Test-Path $installPath) {
    Remove-Item "$installPath/*" -Recurse -Force
} else {
    New-Item -ItemType Directory -Force -Path $installPath | Out-Null
}

# copy module files
Copy-Item -Path "$PSScriptRoot/src/*" -Destination $installPath -Recurse -Force
