$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Get index of a value in provided array from selection menu.
.PARAMETER Array
Array of strings to get the selection menu.
.PARAMETER Message
Optional menu header to display.
#>
function Get-ArrayIndexMenu {
    [CmdletBinding()]
    param (
        [Alias('a')]
        [Parameter(Mandatory)]
        [string[]]$Array,

        [Alias('m')]
        [string]$Message
    )

    # get array length for indentation calculation
    $arrayLen = "$($Array.Count)".Length
    # create selection menu
    $msg = (
        , "`n`e[4m$($Message ? $Message : 'Select option')`e[0m" +
        $Array.ForEach({
                $index = [array]::IndexOf($Array, $_)
                $indent = ' ' * ($arrayLen - "$index".Length + 1)
                "$indent[$index] - $_"
            }) + ''
    ) -join "`n"
    # get selection
    do {
        $i = Read-Host -Prompt $msg
    } until ($i -and $i -in 0..($Array.Count - 1))

    # return array index
    return $i
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
        [Parameter(Mandatory)]
        [scriptblock]$Script
    )
    do {
        try {
            Invoke-Command -ScriptBlock $Script
            $exit = $true
        } catch [System.Net.Http.HttpRequestException] {
            Write-Host 'Retrying...'
        } catch {
            Write-Error $_
            $exit = $true
        }
    } until ($exit)
}