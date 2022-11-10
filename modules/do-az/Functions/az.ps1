$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Set Az Context and eventually connect to Azure.
.PARAMETER Subscription
Subscription Name or ID.
.PARAMETER Tenant
Tenant Name or ID.
#>
function Connect-AzContext {
    [CmdletBinding()]
    param (
        [Alias('s')]
        [string]$Subscription,

        [Alias('t')]
        [string]$Tenant
    )

    begin {
        $ctx = Get-AzContext
    }

    process {
        if ($ctx) {
            if ($PSBoundParameters.Subscription -and $PSBoundParameters.Subscription -notin @($ctx.Subscription.Id, $ctx.Subscription.Name)) {
                $ctx = Invoke-CommandRetry {
                    Set-AzContext -Subscription $Subscription -Tenant $ctx.Tenant.Id
                }
            }
        } else {
            $param = @{}
            if ($PSBoundParameters.Subscription) {
                $param.Subscription = $Subscription
            }
            if ($PSBoundParameters.Tenant) {
                $param.Tenant = $Tenant
            }

            $ctx = Invoke-CommandRetry {
                try {
                    (Connect-AzAccount @param -WarningAction Stop 3>$null).Context
                } catch [System.Management.Automation.ActionPreferenceStopException] {
                    (Connect-AzAccount @param -UseDeviceAuthentication).Context
                } catch {
                    Write-Verbose $_.Exception.GetType().FullName
                    Write-Error $_
                }
            }
        }
    }

    end {
        return $ctx
    }
}

<#
.SYNOPSIS
Set subscription context from selection menu.
#>
function Set-SubscriptionMenu {
    [CmdletBinding()]
    param (
        [switch]$cli
    )
    # query graph api for subscriptions
    $query = "ResourceContainers | where type =~ 'microsoft.resources/subscriptions' | project name, subscriptionId"
    $subscriptions = Invoke-CommandRetry {
        Search-AzGraph -Query $query | Sort-Object name
    }

    # select subscription from menu
    if ($subscriptions.Count -gt 1) {
        $i = Get-ArrayIndexMenu -Array $subscriptions.name -Message 'Select subscription'
    } else {
        $i = 0
    }
    if ($cli) {
        az account set --subscription $subscriptions[$i].subscriptionId
        az account show | ConvertFrom-Json | Select-Object name, id, tenantId, state
    } else {
        $sub = (Connect-AzContext $subscriptions[$i].subscriptionId).Subscription
    }

    return $sub
}

Set-Alias -Name ssm -Value Set-SubscriptionMenu

<#
.SYNOPSIS
Send request to Azure REST API.
.PARAMETER Scope
Request scope.
.PARAMETER ApiVersion
API version.
.PARAMETER Method
Request method. Allowed values: Get, Patch, Put, Delete. Default: Get.
.PARAMETER Body
Request payload provided as string or hashtable.
.PARAMETER InFile
Request payload provided as path to file.
.PARAMETER Output
Output format. Allowed values: json, jsonc, object. Default: object.
#>
function Invoke-AzApiRequest {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Alias('s')]
        [Parameter(Mandatory, Position = 0)]
        [string]$Scope,

        [Alias('a')]
        [Parameter(Mandatory, Position = 1)]
        [string]$ApiVersion,

        [Parameter(ParameterSetName = 'Default')]
        [string]$Filter,

        [Parameter(ParameterSetName = 'Default')]
        [string[]]$Select,

        [Alias('m')]
        [ValidateSet('Get', 'Patch', 'Put', 'Delete')]
        [string]$Method = 'Get',

        [Alias('b')]
        [Parameter(Mandatory, ParameterSetName = 'Payload:Body')]
        [ValidateNotNullorEmpty()]
        [object]$Body,

        [Alias('f')]
        [Parameter(Mandatory, ParameterSetName = 'Payload:File')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = "'{0}' is not a valid path.")]
        [string]$InFile,

        [Alias('o')]
        [ValidateSet('json', 'jsonc', 'object')]
        [string]$Output = 'object'
    )

    begin {
        $params = @{
            Method         = $Method
            Authentication = 'Bearer'
            Token          = (Get-AzAccessToken -ResourceTypeName 'Arm').Token | ConvertTo-SecureString -AsPlainText -Force
            Headers        = @{ 'Content-Type' = 'application/json' }
        }

        # add payload
        if ($Method -in @('Patch', 'Put')) {
            if ($Body) {
                $params.Body = if ($Body.GetType().Name -eq 'Hashtable') {
                    $Body | ConvertTo-Json -Depth 99
                } else {
                    $Body
                }
            } elseif ($InFile) {
                $params.InFile = $InFile
            }
        }

        # build uri
        $uri = "https://management.azure.com$($Scope)?api-version=$ApiVersion"
        if ($PSBoundParameters.Filter) {
            $uri += "&`$filter=$($Filter.Replace(' ', '%20'))"
        }
        if ($PSBoundParameters.Select) {
            $uri += "&`$select=$(($Select -replace ' +') -join ',')"
        }

        $response = $null
        $responseList = [Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        do {
            $response = Invoke-CommandRetry {
                Invoke-RestMethod @params -Uri $uri -Verbose
            }
            if ($response.value) {
                $response.value.ForEach({ $responseList.Add($_) })
            } else {
                $response.ForEach({ $responseList.Add($_) })
            }
            if ($response.nextLink) {
                $uri = $response.nextLink
            }
        } while ($response.nextLink)
    }

    end {
        switch ($Output) {
            'object' {
                return $responseList
            }
            'json' {
                return $responseList | ConvertTo-Json -Depth 10
            }
            'jsonc' {
                return $responseList | ConvertTo-Json -Depth 10 | jq
            }
        }
    }
}
