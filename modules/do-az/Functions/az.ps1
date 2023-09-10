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
Get OAuth2 access token from login.microsoftonline.com for the current user or specified Service Principal.

.PARAMETER ResourceUrl
Resource url for that you're requesting token, e.g. 'https://graph.microsoft.com/'.
.PARAMETER ClientId
Service Principal application id.
.PARAMETER ClientSecret
Service Principal credential.
.PARAMETER AsSecureString
Return token as a secure string.
#>
function Get-MsoToken {
    [CmdletBinding(DefaultParameterSetName = 'BuiltIn')]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceUrl = 'https://management.core.windows.net/',

        [Alias('i')]
        [Parameter(Mandatory, ParameterSetName = 'ServicePrincipal')]
        [guid]$ClientId,

        [Alias('s')]
        [Parameter(Mandatory, ParameterSetName = 'ServicePrincipal')]
        [string]$ClientSecret,

        [switch]$AsSecureString
    )

    process {
        $token = switch ($PsCmdlet.ParameterSetName) {
            BuiltIn {
                Invoke-CommandRetry {
                    Get-AzAccessToken -ResourceUrl $ResourceUrl
                }
            }
            ServicePrincipal {
                $params = @{
                    Uri     = "https://login.microsoftonline.com/$((Get-AzContext).Tenant.Id)/oauth2/token"
                    Method  = 'POST'
                    Headers = @{ 'Content-Type' = 'application/x-www-form-urlencoded' }
                    Body    = @{
                        grant_type    = 'client_credentials'
                        client_id     = $ClientId
                        client_secret = $ClientSecret
                        resource      = $ResourceUrl
                    }
                }
                $oauth2Token = Invoke-CommandRetry {
                    Invoke-RestMethod @params
                }
                [PSCustomObject]@{
                    Token     = $oauth2Token.access_token
                    ExpiresOn = Get-Date -UnixTimeSeconds $oauth2Token.expires_on
                    Type      = 'Bearer'
                    TenantId  = $TENANT_ID
                    UserId    = $ClientId
                }
            }
        }
        if ($AsSecureString) {
            $token = ConvertTo-SecureString -String $token.Token -AsPlainText -Force
        }
    }

    end {
        return $token
    }
}

<#
.SYNOPSIS
Set subscription context from selection menu.

.PARAMETER cli
Switch whether to set the context for azure-cli.
#>
function Set-SubscriptionMenu {
    [CmdletBinding(SupportsShouldProcess)]
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
    if ($PSCmdlet.ShouldProcess($i)) {
        $sub = if ($cli) {
            az account set --subscription $subscriptions[$i].subscriptionId
            az account show | ConvertFrom-Json | Select-Object name, id, tenantId, state
        } else {
            (Connect-AzContext $subscriptions[$i].subscriptionId).Subscription
        }
    }

    return $sub
}

Set-Alias -Name ssm -Value Set-SubscriptionMenu

<#
.SYNOPSIS
Send request to Azure REST API.

.PARAMETER Path
Request path.
.PARAMETER ApiVersion
API version.
.PARAMETER Method
Request method. Allowed values: Get, Patch, Post, Put, Delete. Default: Get.
.PARAMETER Body
Request payload provided as string or hashtable.
.PARAMETER InFile
Request payload provided as path to file.
.PARAMETER Output
Output format. Allowed values: json, object. Default: object.
.PARAMETER Filter
Filter specified for the API request.
.PARAMETER Select
Select specific fields in the API request.
#>
function Invoke-AzApiRequest {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory, Position = 1)]
        [string]$ApiVersion,

        [string]$Filter,

        [string[]]$Select,

        [ValidateSet('Get', 'Patch', 'Post', 'Put', 'Delete')]
        [string]$Method = 'Get',

        [Parameter(Mandatory, ParameterSetName = 'Payload:Body')]
        [ValidateNotNullorEmpty()]
        [object]$Body,

        [Alias('f')]
        [Parameter(Mandatory, ParameterSetName = 'Payload:File')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = "'{0}' is not a valid path.")]
        [string]$InFile,

        [ValidateSet('json', 'object')]
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
        if ($Method -in @('Patch', 'Post', 'Put')) {
            if ($Body) {
                $params.Body = switch -Regex ($Body.GetType().Name) {
                    String {
                        $Body
                    }
                    'Hashtable|OrderedDictionary' {
                        $Body | ConvertTo-Json -Depth 99
                    }
                    Default {
                        $null
                    }
                }
            } elseif ($InFile) {
                $params.InFile = $InFile
            }
        }

        # build Uri
        $Query = "?api-version=$ApiVersion"
        if ($PSBoundParameters.Filter) {
            $Query += "&`$filter=$($Filter.Replace(' ', '%20'))"
        }
        if ($PSBoundParameters.Select) {
            $Query += "&`$select=$(($Select -replace ' +') -join ',')"
        }
        $params.Uri = [System.UriBuilder]::new('https', 'management.azure.com', 443, $Path, $Query).Uri

        # initialize variables
        $response = $null
        $responseList = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        Write-Verbose "$($params.Method.ToUpper()) $($params.Uri)"
        if ($params.Body) {
            Write-Verbose "Body`n$($params.Body)"
        }
        do {
            $response = Invoke-CommandRetry {
                Invoke-RestMethod @params
            }
            if ($response.value) {
                $response.value.ForEach({ $responseList.Add($_) })
            } else {
                $response.ForEach({ $responseList.Add($_) })
            }
            if ($response.nextLink) {
                $params.Uri = $response.nextLink
            }
        } while ($response.nextLink)
    }

    end {
        switch ($Output) {
            object {
                return $responseList
            }
            json {
                if (Get-Command jq -CommandType Application -ErrorAction SilentlyContinue) {
                    return $responseList | ConvertTo-Json -Depth 99 | jq
                } else {
                    return $responseList | ConvertTo-Json -Depth 99
                }
            }
        }
    }
}
