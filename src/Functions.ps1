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
            Invoke-Command -ScriptBlock $Script -ErrorAction Stop
            $exit = $true
        } catch [System.Net.Http.HttpRequestException] {
            Write-Verbose 'Retrying...'
        } catch {
            Write-Error $_
            $exit = $true
        }
    } until ($exit)
}

<#
.SYNOPSIS
Set Az Context and eventually connect to Azure.
.PARAMETER Subscription
Subscription Name or ID.
#>
function Connect-AzContext {
    param (
        [Alias('s')]
        [string]$Subscription
    )
    $ctx = Get-AzContext
    if ($ctx) {
        if ($Subscription -and $Subscription -notin @($ctx.Subscription.Id, $ctx.Subscription.Name)) {
            $ctx = Invoke-CommandRetry {
                Set-AzContext -Subscription $Subscription -Tenant $ctx.Subscription.TenantId
            }
        }
    } else {
        $ctx = Invoke-CommandRetry {
            if ($Subscription) {
                try {
                    (Connect-AzAccount -Subscription $Subscription -WarningAction Stop).Context
                } catch {
                    (Connect-AzAccount -Subscription $Subscription -UseDeviceAuthentication).Context
                }
            } else {
                try {
                    (Connect-AzAccount -WarningAction Stop).Context
                } catch {
                    (Connect-AzAccount -UseDeviceAuthentication).Context
                }
            }
        }
    }

    return $ctx
}

<#
.SYNOPSIS
Set subscription context from selection menu.
#>
function Set-SubscriptionMenu {
    # query graph api for subscriptions
    $tenantId = (Get-AzContext).Subscription.TenantId
    $query = "ResourceContainers | where type =~ 'microsoft.resources/subscriptions' | project name, subscriptionId"
    $subscriptions = Search-AzGraph -Query $query -ManagementGroup $tenantId | Sort-Object name

    # select subscription from menu
    $i = Get-ArrayIndexMenu -Array $subscriptions.name -Message 'Select subscription'
    $sub = (Connect-AzContext $subscriptions[$i].subscriptionId).Subscription

    return $sub
}

Set-Alias -Name ssm -Value Set-SubscriptionMenu

<#
.SYNOPSIS
Get Azure token from current context.
#>
function Get-AzAccessToken {
    # get current context
    $ctx = Connect-AzContext

    # get token
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient]::new($azProfile)
    $token = $profileClient.AcquireAccessToken($ctx.Subscription.TenantId)

    return $token
}

<#
.SYNOPSIS
Send Azure API request.
.PARAMETER ResourceId
Resource ID of the resource to query.
.PARAMETER ApiVersion
API version of the resource to query.
.PARAMETER Output
Output format.
#>
function Get-AzApiRequest {
    [CmdletBinding()]
    param (
        [Alias('r')]
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ResourceId,

        [Alias('a')]
        [Parameter(Mandatory)]
        [string]$ApiVersion,

        [Alias('o')]
        [ValidateSet('json', 'jsonc', 'object')]
        [string]$Output = 'object'
    )

    begin {
        $responseList = [Collections.Generic.List[PSCustomObject]]::new()
        $params = @{
            Method         = 'Get'
            Authentication = 'Bearer'
            Token          = (Get-AzAccessToken).AccessToken | ConvertTo-SecureString -AsPlainText -Force
            Headers        = @{ 'Content-Type' = 'application/json' }
            Body           = @{ 'api-version' = $ApiVersion }
        }
    }

    process {
        $response = Invoke-CommandLoop {
            Invoke-RestMethod @params -Uri "https://management.azure.com$ResourceId"
        }
        $responseList.Add($response)
    }

    end {
        switch ($Output) {
            { $_ -eq 'object' } {
                $responseList
            }
            { $_ -in 'json' } {
                $responseList | ConvertTo-Json -Depth 5
            }
            { $_ -eq 'jsonc' } {
                $responseList | ConvertTo-Json -Depth 5 | jq
            }
        }
    }
}
