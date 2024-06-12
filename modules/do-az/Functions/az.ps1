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

.PARAMETER ResourceTypeName
Optional resource type name, supported values: AadGraph, AnalysisServices, AppConfiguration, Arm, Attestation, Batch, DataLake, KeyVault, MSGraph, OperationalInsights, ResourceManager, Storage, Synapse.
Default value is Arm if not specified.
.PARAMETER ResourceUrl
Resource url for that you're requesting token, e.g. 'https://graph.microsoft.com/'.
.PARAMETER ClientId
Service Principal application id.
.PARAMETER ClientSecret
Service Principal credential.
.PARAMETER Credential
PSCredential object with username and password.
.PARAMETER AsSecureString
Return token as a secure string.
#>
function Get-MsoToken {
    [CmdletBinding(DefaultParameterSetName = 'ByType')]
    param (
        [Alias('t')]
        [Parameter(ParameterSetName = 'ByType')]
        [ValidateSet('AadGraph', 'AnalysisServices', 'AppConfiguration', 'Arm', 'Attestation', 'Batch', 'DataLake', 'KeyVault', 'ManagedHsm', 'MSGraph', 'OperationalInsights', 'ResourceManager', 'Storage', 'Synapse')]
        [string]$ResourceTypeName = 'Arm',

        [Alias('u')]
        [Parameter(Mandatory, ParameterSetName = 'ByUrl')]
        [string]$ResourceUrl,

        [Alias('i')]
        [Parameter(Mandatory, ParameterSetName = 'ServicePrincipal')]
        [Parameter(ParameterSetName = 'ByUrl')]
        [guid]$ClientId,

        [Alias('s')]
        [Parameter(Mandatory, ParameterSetName = 'ServicePrincipal')]
        [Parameter(ParameterSetName = 'ByUrl')]
        [string]$ClientSecret,

        [Alias('c')]
        [Parameter(Mandatory, ParameterSetName = 'Credential')]
        [Parameter(ParameterSetName = 'ByUrl')]
        [System.Management.Automation.PSCredential]$Credential,

        [switch]$AsSecureString
    )

    begin {
        # calculate variables based on PSBoundParameters
        if (-not $PSBoundParameters.ResourceUrl) {
            $ResourceUrl = 'https://management.azure.com'
        }
        if ($PSBoundParameters.Credential) {
            $ClientId = $Credential.GetNetworkCredential().UserName
            $ClientSecret = $Credential.GetNetworkCredential().Password
        }
    }

    process {
        $token = if ($PsCmdlet.ParameterSetName -eq 'ByType') {
            # get token for the logged-in user by ResourceTypeName
            Invoke-CommandRetry {
                Get-AzAccessToken -ResourceTypeName $ResourceTypeName
            }
        } elseif ($ClientId) {
            # get token for the specified Url and Client
            $tenantId = (Get-AzContext).Tenant.Id
            $params = @{
                Uri     = "https://login.microsoftonline.com/$tenantId/oauth2/token"
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
                TenantId  = $tenantId
                UserId    = $ClientId
            }
        } else {
            Invoke-CommandRetry {
                # get token for the logged-in user for the specified Url
                Get-AzAccessToken -ResourceUrl $ResourceUrl
            }
        }

        if ($AsSecureString) {
            # convert token to secure string
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
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgAzGetSubscriptions @args })]
        [string]$Subscription,

        [switch]$Cli
    )

    begin {
        $subscription = if ($PsBoundParameters.Subscription) {
            $PsBoundParameters.Subscription
        } else {
            $query = [string]::Join(' | ',
                'ResourceContainers',
                'where type =~ "microsoft.resources/subscriptions"',
                'project subscriptionId, name'
            )
            Invoke-AzGraph -Query $query | Get-ArrayIndexMenu -Value | Select-Object -ExpandProperty name
        }
    }

    process {
        if ($subscription) {
            $sub = if ($PsBoundParameters.Cli) {
                az account set --subscription $subscription
                az account show | ConvertFrom-Json | Select-Object name, id, tenantId, state
            } else {
                (Connect-AzContext $subscription).Subscription | Select-Object Name, Id, TenantId, State
            }
        }
    }

    end {
        return $sub
    }
}

Set-Alias -Name ssm -Value Set-SubscriptionMenu


<#
.SYNOPSIS
Send request to Azure REST API.

.PARAMETER Endpoint
API endpoint.
.PARAMETER Path
Request path.
.PARAMETER ApiVersion
API version.
.PARAMETER Token
Azure ARM access token.
.PARAMETER Filter
Filter specified for the API request.
.PARAMETER Select
Select specific fields in the API request.
.PARAMETER Method
Request method. Allowed values: Get, Patch, Post, Put, Delete. Default: Get.
.PARAMETER Body
Request payload provided as string or hashtable.
.PARAMETER InFile
Request payload provided as path to file.
.PARAMETER SkipPagination
Switch whether or not to retrieve paginated results.
.PARAMETER JsonOutput
Switch whether to return a response as json.
#>
function Invoke-AzApiRequest {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint = 'management.azure.com',

        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Path,

        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion,

        [securestring]$Token,

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

        [switch]$SkipPagination,

        [switch]$JsonOutput
    )

    begin {
        # get Azure ARM access token if not prvided
        if (-not $Token) {
            $Token = Get-MsoToken -AsSecureString
        }
        # build Azure REST API request parameters for splatting
        $params = @{
            Method         = $Method
            Authentication = 'Bearer'
            Token          = $Token
            Headers        = @{ 'Content-Type' = 'application/json' }
            ErrorAction    = 'Stop'
        }

        # get the latest stable Azure REST API version for the specified Path provided
        if (-not $ApiVersion -and $Endpoint -eq 'management.azure.com') {
            $split = $Path.Split('/')
            if ($split[5] -eq 'providers') {
                Write-Warning 'Missing ApiVersion parameter. Getting the latest stable API version.' -WarningAction Continue
                $ApiVersion = Invoke-CommandRetry {
                    Get-AzResourceProvider -ProviderNamespace $split[6] -ErrorAction 'Stop' `
                    | Select-Object -ExpandProperty ResourceTypes `
                    | Where-Object { $_.ResourceTypeName -eq $split[7] } `
                    | Select-Object -ExpandProperty ApiVersions `
                    | Where-Object { $_ -notmatch '-preview$' } `
                    | Select-Object -First 1
                }
                if ($ApiVersion) {
                    Write-Host "`nLatest stable API version for `e[1m$($split[6])/$($split[7])`e[22m: `e[1m${ApiVersion}`e[22m" -ForegroundColor Yellow
                } else {
                    Write-Warning "Latest stable API version for `e[1m$($split[6])/$($split[7])`e[21m not found."
                    break
                }
            } else {
                Write-Warning 'Missing ApiVersion parameter. Provide correct API version.'
                break
            }
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

        # build Query
        $sb = [System.Text.StringBuilder]::new()
        if ($ApiVersion) {
            $sb.Append("?api-version=$ApiVersion") | Out-Null
        }
        if ($PSBoundParameters.Query) {
            $sb.Append("&$($Query.Replace(' ', '%20'))") | Out-Null
        }
        $qry = $sb.ToString()

        # initialize collection to store the response
        $responseList = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        # calculate request Uri
        $params.Uri = [System.UriBuilder]::new('https', $Endpoint, 443, $Path, $qry).Uri
        # write verbose messages
        Write-Verbose "$($params.Method.ToUpper()) $($params.Uri)"
        if ($params.Body) {
            Write-Verbose "Body`n$($params.Body)"
        }
        do {
            # send API request
            $response = try {
                Invoke-CommandRetry {
                    Invoke-RestMethod @params
                }
            } catch {
                if ($PSBoundParameters.ErrorAction -eq 'SilentlyContinue') {
                    Write-Verbose $_
                } else {
                    Write-Verbose $_.Exception.GetType().FullName
                    Write-Error $_
                }
                $null
            }
            # add response to response list
            if ($response.value) {
                $response.value.ForEach({ $responseList.Add($_) })
            } else {
                $response.ForEach({ $responseList.Add($_) })
            }
            # check pagination
            if ($response.nextLink) {
                if ($SkipPagination) {
                    $response.nextLink = $null
                } else {
                    $params.Uri = $response.nextLink
                }
            }
        } while ($response.nextLink)
    }

    end {
        # return response
        if ($JsonOutput) {
            if (Get-Command jq -CommandType Application -ErrorAction SilentlyContinue) {
                return $responseList | ConvertTo-Json -Depth 99 | jq
            } else {
                return $responseList | ConvertTo-Json -Depth 99
            }
        } else {
            return $responseList
        }
    }
}
