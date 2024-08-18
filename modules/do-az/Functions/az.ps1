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
Get Azure context properties.
.DESCRIPTION
Get Azure context properties for the current user or service principal.

.PARAMETER AzureCli
Switch whether to get context properties for azure-cli.
#>
function Get-AzCtx {
    [CmdletBinding()]
    param (
        [Alias('cli')]
        [switch]$AzureCli
    )

    begin {
        # get current Azure context and store it in a dictionary
        if ($AzureCli) {
            $ctx = az account show -o json | ConvertFrom-Json
            $dict = [ordered]@{
                TenantId         = $ctx.tenantId
                SubscriptionId   = $ctx.id
                SubscriptionName = $ctx.name
                UserType         = $ctx.user.type
            }
        } else {
            $ctx = Get-AzContext
            $dict = [ordered]@{
                TenantId         = $ctx.Tenant.Id
                SubscriptionId   = $ctx.Subscription.Id
                SubscriptionName = $ctx.Subscription.Name
                UserType         = $ctx.Account.Type
            }
        }
    }

    process {
        # add user or service principal properties to the dictionary
        if ($AzureCli) {
            if ($ctx.user.type -eq 'servicePrincipal') {
                $dict.PrincipalName = Invoke-CommandRetry {
                    Get-AzADServicePrincipal -ApplicationId $ctx.user.name -ErrorAction Stop
                } | Select-Object -ExpandProperty DisplayName
                $dict.PrincipalId = $ctx.user.name
            } else {
                $dict.UserName = $ctx.user.name
            }
        } else {
            if ($ctx.Account.Type -eq 'servicePrincipal') {
                $dict.PrincipalName = Invoke-CommandRetry {
                    Get-AzADServicePrincipal -ApplicationId $ctx.Account.Id -ErrorAction Stop
                } | Select-Object -ExpandProperty DisplayName
                $dict.PrincipalId = $ctx.Account.Id
            } else {
                $dict.UserName = $ctx.Account.Id
                $dict.UserId = ($ctx.Account.ExtendedProperties.HomeAccountId).Split('.')[0]
            }
        }
    }

    end {
        # return context dictionary
        [PSCustomObject]$dict
    }
}


<#
.SYNOPSIS
Retrieves the available API versions for Azure resource types.

.DESCRIPTION
This function queries Azure to get a list of all available API versions for the specified Azure resource types.
It can be used to ensure that scripts or deployments target compatible API versions.

.PARAMETER Type
Specifies the resource type to get the Azure REST API versions for.
.PARAMETER Id
Specifies the resource id to get the Azure REST API versions for.
.PARAMETER Option
Specifes the option to retrieve API versions:
- Def:   : latest stable and if not found latest preview (default option)
- Latest : latest version
- Stable : latest stable version
- All    : all versions

.EXAMPLE
# :get api versions by resource type
$Type = 'Microsoft.MachineLearningServices/workspaces'
Get-AzResourceTypeApiVersions $Type
Get-AzResourceTypeApiVersions $Type -Option 'Latest'
Get-AzResourceTypeApiVersions $Type -Option 'Stable'
Get-AzResourceTypeApiVersions $Type -Option 'All'
# :get AIP versions by resource id
$Id = '/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleAssignmentsUsageMetrics'
Get-AzResourceTypeApiVersions -Id $Id

.NOTES
Requires the Azure PowerShell module to be installed and an active Azure subscription login.
#>
function Get-AzResourceTypeApiVersions {
    [CmdletBinding(DefaultParameterSetName = 'ByType')]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByType')]
        [string]$Type,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ById')]
        [string]$Id,

        [ValidateSet('Def', 'Latest', 'Stable', 'All')]
        [string]$Option = 'Def'
    )

    process {
        # determina provider namespace and resource type
        switch ($PSCmdlet.ParameterSetName) {
            ById {
                $split = $Id.Split('/')
                $idx = [array]::IndexOf($split, 'providers')
                if ($idx -ge 0) {
                    $namespace, $type = $split[($idx + 1)..($idx + 2)]
                } else {
                    Write-Warning 'Cannot determine resource type. Provide correct Azure resource id.'
                    exit 1
                }
            }
            ByType {
                $split = $Type.Split('/')
                if ($split.Count -eq 2 -and $split[0] -match '^microsoft\.\w+$') {
                    $namespace, $type = $split
                } else {
                    Write-Warning 'Provider resource type is incorrect.'
                    exit 1
                }
            }
        }

        [string[]]$ApiVersions = Invoke-CommandRetry {
            Get-AzResourceProvider -ProviderNamespace $namespace -ErrorAction 'Stop' `
            | Select-Object -ExpandProperty ResourceTypes `
            | Where-Object { $_.ResourceTypeName -eq $type } `
            | Select-Object -ExpandProperty ApiVersions
        }

        if (-not $ApiVersions) {
            Write-Warning "API version for `e[4m$namespace/$type`e[24m not found."
            break
        } elseif ($Option -in @('Stable', 'Def')) {
            $stable = $ApiVersions -notmatch '-preview$'
        }
    }

    end {
        switch ($Option) {
            All {
                $ApiVersions
                continue
            }
            Latest {
                $ApiVersions[0]
                continue
            }
            Stable {
                $stable[0]
                continue
            }
            Def {
                $stable.Count -gt 0 ? $stable[0] : $ApiVersions[0]
                continue
            }
        }
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
.PARAMETER AsPlainText
When set, the function will convert secret in secure string to the decrypted plaintext string as output.
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

        [switch]$AsPlainText
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
                # todo - remove WarningAction on Az 13.0.0 release
                Get-AzAccessToken -ResourceTypeName $ResourceTypeName -AsSecureString -WarningAction SilentlyContinue
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
                Token     = $oauth2Token.access_token | ConvertTo-SecureString -AsPlainText
                ExpiresOn = Get-Date -UnixTimeSeconds $oauth2Token.expires_on
                TenantId  = $tenantId
                UserId    = $ClientId
                Type      = 'Bearer'
            }
        } else {
            # get token for the logged-in user for the specified Url
            Invoke-CommandRetry {
                # todo - remove WarningAction on Az 13.0.0 release
                Get-AzAccessToken -ResourceUrl $ResourceUrl -AsSecureString -WarningAction SilentlyContinue
            }
        }

        if ($AsPlainText) {
            # convert token from secure string
            $props = @(
                @{ Name = 'Token'; Expression = { $_.Token | ConvertFrom-SecureString -AsPlainText } }
                'ExpiresOn'
                'TenantId'
                'UserId'
                'Type'
            )
            $token = $token | Select-Object $props
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
            $Token = (Get-MsoToken).Token
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
            $ApiVersion = Get-AzResourceTypeApiVersions -Id $Path
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
