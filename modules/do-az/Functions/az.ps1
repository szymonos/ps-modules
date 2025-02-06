<#
.SYNOPSIS
Set Az Context and eventually connect to Azure.

.PARAMETER Subscription
Subscription Name or ID.
.PARAMETER Tenant
Tenant Name or ID.
.PARAMETER AzureCli
Switch whether to connect using the current azure-cli context with user/password authentication.
#>
function Connect-AzContext {
    [CmdletBinding()]
    param (
        [Alias('s')]
        [string]$Subscription,

        [Alias('t')]
        [string]$Tenant,

        [Alias('cli')]
        [switch]$AzureCli
    )

    begin {
        if ($PSBoundParameters.AzureCli) {
            try {
                Get-Command az -CommandType Application -ErrorAction Stop | Out-Null
                $account = az account show --out json | ConvertFrom-Json
                if ($account) {
                    if ($account.user.type -eq 'user') {
                        while (Get-AzContext) {
                            Disconnect-AzAccount | Out-Null
                        }
                        $ctx = $null
                    } else {
                        Write-Warning 'Service principal login not supported.'
                        $abort = $true
                        return
                    }
                } else {
                    $abort = $true
                    return
                }
            } catch {
                Write-Warning 'Azure CLI not found.'
                $abort = $true
                return
            }
        } else {
            $ctx = Get-AzContext
        }
    }

    process {
        if ($abort) {
            $ctx = $null
        } else {
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
                } elseif ($PSBoundParameters.AzureCli) {
                    $param.Subscription = $account.id
                }
                if ($PSBoundParameters.Tenant) {
                    $param.Tenant = $Tenant
                } elseif ($PSBoundParameters.AzureCli) {
                    $param.Tenant = $account.tenantId
                }

                $ctx = Invoke-CommandRetry {
                    if ($PSBoundParameters.AzureCli) {
                        Update-AzConfig -DefaultSubscriptionForLogin $param.Subscription | Out-Null
                        $param.Credential = Get-Credential -UserName $account.user.name
                        $param.WarningAction = 'SilentlyContinue'
                        Connect-AzAccount @param | Select-Object -ExpandProperty Context
                    } else {
                        try {
                            $param.WarningAction = 'Stop'
                            Connect-AzAccount @param 3>$null | Select-Object -ExpandProperty Context
                        } catch [System.Management.Automation.ActionPreferenceStopException] {
                            $param.WarningAction = 'SilentlyContinue'
                            $param.UseDeviceAuthentication = $true
                            Connect-AzAccount @param | Select-Object -ExpandProperty Context
                        } catch {
                            Write-Verbose $_.Exception.GetType().FullName
                            Write-Error $_
                        }
                    }
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
        if ($PSBoundParameters.AzureCli) {
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
        if ($PSBoundParameters.AzureCli) {
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
                if ($idx -ge 0 -and $split[$idx + 1] -match '^microsoft\.\w+$' -and $split[$idx + 2]) {
                    $namespace, $type = $split[($idx + 1)..($idx + 2)]
                } else {
                    Write-Error "Cannot determine resource type. ResourceId is incorrect ($Id)."
                }
            }
            ByType {
                $split = $Type.Split('/')
                if ($split.Count -eq 2 -and $split[0] -match '^microsoft\.\w+$') {
                    $namespace, $type = $split
                } else {
                    Write-Error "Provider resource type is incorrect ($Type)."
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
Set Azure KeyVault access policy using Azure REST API request

.PARAMETER VaultId
Resource id of the Azure KeyVault
.PARAMETER VaultName
Azure KeyVault name.
.PARAMETER Operation
Operation to perform. Available options: add, replace, remove.
.PARAMETER ObjectId
ObjectId of the policy asignee, e.g. user, group, service principal.
It will assign policy to the current user if not specified
.PARAMETER PermissionsToKeys
List of Keys permissions.
.PARAMETER PermissionsToSecrets
List of Secrets permissions.
.PARAMETER PermissionsToCertificates
List of Certificates permissions.
.PARAMETER ApiVersion
KeyVault API version.
#>
function Set-AzKeyVaultAccessPolicyApi {
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ById')]
        [string]$VaultId,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName')]
        [string]$VaultName,

        [ValidateSet('add', 'remove', 'replace')]
        [string]$Operation = 'add',

        [guid]$ObjectId,

        [string[]]$PermissionsToKeys,

        [string[]]$PermissionsToSecrets,

        [string[]]$PermissionsToCertificates,

        [string]$ApiVersion = '2022-07-01'
    )

    # get VaultId for the API request if name provided
    if ($VaultName) {
        $VaultId = (Get-AzGraphResourceByName -ResourceName $VaultName -ResourceType 'microsoft.keyvault/vaults').id
        if (-not $VaultId) {
            Write-Warning "Key-Vault not found ($VaultName)."
            exit 1
        }
    }

    # get current user object id if non provided, to perform the access policy operation on
    $ctx = Get-AzContext
    if (-not $ObjectId) {
        $ObjectId = Invoke-CommandRetry {
            Get-AzADUser -UserPrincipalName $ctx.Account.Id | Select-Object -ExpandProperty Id
        }
    }

    # build KeyVault API request parameters
    $apiParams = @{
        Method     = 'Put'
        Path       = "$($VaultId)/accessPolicies/$Operation"
        ApiVersion = $ApiVersion
        Body       = @{
            properties = @{
                accessPolicies = @(
                    @{
                        tenantId    = $ctx.Tenant.Id
                        objectId    = $ObjectId
                        permissions = @{
                            keys         = $PermissionsToKeys ?? @()
                            secrets      = $PermissionsToSecrets ?? @()
                            certificates = $PermissionsToCertificates ?? @()
                        }
                    }
                )
            }
        }
    }
    # run the KeyVault API request
    Invoke-AzApiRequest @apiParams
}


<#
.SYNOPSIS
Gets a certificate from a key vault as X509Certificate2Collection.

.PARAMETER VaultName
Specifies the name of the key vault to which the secret belongs.
.PARAMETER Name
Specifies the name of the secret to get.
.PARAMETER Version
Specifies the secret version.
#>
function Get-KeyVaultCertificate {
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param (
        [string]$VaultName,

        [Parameter(Mandatory, ParameterSetName = 'get')]
        [string]$Name,

        [Parameter(ParameterSetName = 'get')]
        [switch]$IncludeVersions,

        [Parameter(ParameterSetName = 'get')]
        [string]$Version,

        [Parameter(ParameterSetName = 'get')]
        [switch]$ShowCertificate
    )

    begin {
        # rewrite PSBoundParameters to internal variable
        $param = @{}
        $PSBoundParameters.GetEnumerator() | ForEach-Object { $param[$_.Key] = $_.Value }
        $param.Add('ErrorAction', 'Stop')
        if ($PSBoundParameters.ShowCertificate) {
            $param.Remove('ShowCertificate') | Out-Null
            if ($PSBoundParameters.IncludeVersions) {
                Write-Warning 'IncludeVersions parameter is not supported with ShowCertificate.'
                $param.Remove('IncludeVersions') | Out-Null
            }
        }
        # go into loop trying to get the KeyVault secret
        for ($i = 0; $i -lt 5; $i++) {
            try {
                $certificate = if ($PSBoundParameters.ShowCertificate) {
                    Invoke-CommandRetry { Get-AzKeyVaultSecret @param }
                } else {
                    Invoke-CommandRetry { Get-AzKeyVaultCertificate @param }
                }
            } catch [Microsoft.Azure.KeyVault.Models.KeyVaultErrorException] {
                if ($_.Exception.Message -match 'does not have .+ permission') {
                    if (-not $local:kvPolicy) {
                        # assign KeyVault policy to get secrets
                        $kv = Get-AzGraphResourceByName -ResourceName $VaultName -ResourceType 'microsoft.keyvault/vaults'
                        Write-Verbose "Assigning `"$($PSCmdlet.ParameterSetName)`" $($ShowCertificate ? 'secrets' : 'certificates') policy on the key vault."
                        $paramPolicy = @{
                            Operation = 'add'
                            VaultId   = $kv.id
                            Verbose   = $PSBoundParameters.Verbose ? $true : $false
                        }
                        if ($ShowCertificate) {
                            $paramPolicy.PermissionsToSecrets = $PSCmdlet.ParameterSetName
                        } else {
                            $paramPolicy.PermissionsToCertificates = $PSCmdlet.ParameterSetName
                        }
                        $local:kvPolicy = Set-AzKeyVaultAccessPolicyApi @paramPolicy
                    } else {
                        Write-Verbose 'Sleep 1 second to apply the policy.'
                        Start-Sleep 1
                    }
                } else {
                    Write-Error $_
                    $noAccess = $true
                    break
                }
            } catch {
                Write-Error $_
                $noAccess = $true
                break
            }
        }
    }

    process {
        if (-not $certificate) {
            Write-Warning "No certificate named `"$Name`" found in the `"$VaultName`" key-vault."
            return
        } elseif ($noAccess) {
            return
        }
        if ($ShowCertificate) {
            $certificate.ContentType
            if ($certificate.ContentType -notin @('application/x-pkcs12', 'application/x-pem-file')) {
                Write-Warning "Secret `"$Name`" is not a certificate."
                return
            } else {
                # decode certificates
                $secretValue = $certificate.SecretValue | ConvertFrom-SecureString -AsPlainText
                switch ($certificate.ContentType) {
                    'application/x-pkcs12' {
                        # instantiate X509Certificate2Collection to store the certificate chain
                        $certs = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
                        $certs.Import([Convert]::FromBase64String($secretValue))
                    }
                    'application/x-pem-file' {
                        $certs = $secretValue | ConvertFrom-PEM
                    }
                }
            }
        } else {
            $certs = $certificate
        }
    }

    end {
        return $local:certs
    }

    clean {
        # remove assigned access policy
        if ($local:kvPolicy) {
            Write-Verbose "Removing $($PSCmdlet.ParameterSetName -eq 'get' ? 'secrets' : 'certificates') policy from the key vault."
            $paramPolicy.Operation = 'remove'
            Set-AzKeyVaultAccessPolicyApi @paramPolicy | Out-Null
        }
    }
}


<#
.SYNOPSIS
Gets the secrets in a key vault and assigning get policy if not set.

.PARAMETER VaultName
Specifies the name of the key vault to which the secret belongs.
.PARAMETER Name
Specifies the name of the secret to get.
.PARAMETER AsPlainText
When set, the cmdlet will convert secret in secure string to the decrypted plaintext string as output.
#>
function Get-KeyVaultSecret {
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param (
        [Parameter(Mandatory)]
        [string]$VaultName,

        [Parameter(Mandatory, ParameterSetName = 'get')]
        [string]$Name,

        [Parameter(ParameterSetName = 'get')]
        [switch]$AsPlainText,

        [Parameter(ParameterSetName = 'get')]
        [switch]$IncludeVersions,

        [Parameter(ParameterSetName = 'get')]
        [string]$Version
    )

    begin {
        # rewrite PSBoundParameters to internal variable
        $param = $PSBoundParameters
        $param.Add('ErrorAction', 'Stop')
    }

    process {
        # go into loop trying to get the KeyVault secret
        for ($i = 0; $i -lt 5; $i++) {
            try {
                $secret = Invoke-CommandRetry { Get-AzKeyVaultSecret @param }
                break
            } catch [Microsoft.Azure.KeyVault.Models.KeyVaultErrorException] {
                if ($_.Exception.Message -match 'does not have .+ permission') {
                    if (-not $local:kvPolicy) {
                        # assign KeyVault policy to get secrets
                        $kv = Get-AzGraphResourceByName -ResourceName $VaultName -ResourceType 'microsoft.keyvault/vaults'
                        Write-Verbose "Assigning `"$($PSCmdlet.ParameterSetName)`" secrets policy on the key vault."
                        $paramPolicy = @{
                            Operation            = 'add'
                            VaultId              = $kv.id
                            PermissionsToSecrets = $PSCmdlet.ParameterSetName
                            Verbose              = $PSBoundParameters.Verbose ? $true : $false
                        }
                        $local:kvPolicy = Set-AzKeyVaultAccessPolicyApi @paramPolicy
                    } else {
                        Write-Verbose 'Sleep 1 second to apply the policy.'
                        Start-Sleep 1
                    }
                } else {
                    Write-Error $_
                    break
                }
            } catch {
                Write-Error $_
                break
            }
        }
    }

    end {
        return $local:secret
    }

    clean {
        # remove assigned access policy
        if ($local:kvPolicy) {
            Write-Verbose 'Removing secrets policy from the key vault.'
            $paramPolicy.Operation = 'remove'
            Set-AzKeyVaultAccessPolicyApi @paramPolicy | Out-Null
        }
    }
}


<#
.DESCRIPTION
Get virtual network details from AzGraph.

.PARAMETER VirtualNetwork
Specifies the virtual network name(/subnet) or id.
.PARAMETER AzGraphResource
Switch to return just the AzGraphResource object from the provided id.

.EXAMPLE
$VirtualNetwork = 'mlwmlopsaztest0'
$VirtualNetwork = 'mlwmlopsaztest0/privatelink'
Get-VirtualNetwork -n $VirtualNetwork -Verbose
# :get virtual network by id
$VirtualNetwork = '/subscriptions/73031a72-85cc-45bc-8485-8375031e8bf2/resourceGroups/AZ-RG-AIP-MLWMLOPSAZTEST0/providers/Microsoft.Network/virtualNetworks/mlwmlopsaztest0'
Get-VirtualNetwork -n $VirtualNetwork -AzGraphResource -Verbose
#>
function Get-VirtualNetwork {
    [CmdletBinding()]
    param (
        [Alias('n')]
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ $_.Split('/').Count -in @(1, 2, 9) }, ErrorMessage = "'{0}' is not proper virtual network string.")]
        [string]$VirtualNetwork,

        [switch]$AzGraphResource
    )

    begin {
        $split = $VirtualNetwork.Split('/')

        # determine verbosity level
        $isVerbose = $PSBoundParameters.Verbose ? $true : $false
    }

    process {
        Show-LogContext -Message 'getting virtual network details' -Level VERBOSE
        $vnet = if ($split.Count -le 2) {
            Get-AzGraphResource -ResourceName $split[0] -ResourceType 'microsoft.network/virtualnetworks' -Verbose:$isVerbose
        } else {
            try {
                $resource = [AzGraphResource]$VirtualNetwork
                if ($resource.type -eq 'Microsoft.Network/virtualNetworks') {
                    if ($AzGraphResource) {
                        $resource
                    } else {
                        Get-AzGraphResource -ResourceId $resource.id -Verbose:$isVerbose
                    }
                } else {
                    Show-LogContext "non-virtualNetwork id provided ($VirtualNetwork)" -Level WARNING
                    return $null
                }
            } catch {
                return $null
            }
        }

        if (-not $vnet) {
            Show-LogContext "no virtual network found ($VirtualNetwork)" -Level WARNING
        }
    }

    end {
        return $vnet
    }
}


<#
.SYNOPSIS
Get Azure Private Endpoint by specifying the endpoint name, virtual network, IP or resource it connects to.

.PARAMETER PrivateEndpoint
Private Endpoint id or name.
.PARAMETER VirtualNetwork
Virtual Network id or name of the private endpoint.
.PARAMETER IP
The IP of the private endpoint network interface.
.PARAMETER Resource
Id or name of the resource, private endpoint is connected to.
.PARAMETER GetIP
Switch to get private endpoint IP configurations.

.EXAMPLE
# :by private endpoint name
$PrivateEndpoint = '<private_endpoint_name>'
Get-PrivateEndpoint -e $PrivateEndpoint | Tee-Object -Variable pe
Get-PrivateEndpoint -e $PrivateEndpoint -GetIP | Tee-Object -Variable pe
# :by vnet
$VirtualNetwork = '<virtual_network_name>'
$pe = Get-PrivateEndpoint -n $VirtualNetwork
# get PE with the specified IP
$pe = Get-PrivateEndpoint -n $VirtualNetwork -GetIP
Get-PrivateEndpoint -n $VirtualNetwork -IP '10.99.0.4' | Tee-Object -Variable pe
# :by resource
$Resource = '<target_resource_name>'
$pe = Get-PrivateEndpoint -r $Resource
$pe = Get-PrivateEndpoint -r $Resource -GetIP
# :by connection
$VirtualNetwork = '<virtual_network_name>'
$Resource = '<target_resource_name>'
Get-PrivateEndpoint -n $VirtualNetwork -r $Resource | Tee-Object -Variable pe
Get-PrivateEndpoint -n $VirtualNetwork -r $Resource -GetIP | Tee-Object -Variable pe
# :explore private endpoint result
# list private endpoints
$pe | Select-Object name, resourceGroup, subscription, @{ N = 'primaryIP'; E = { $_.properties.primaryIP } }
# write private endpoint IP configurations
$pe[0].properties.networkInterfaces.ipConfigurations
# explore all properties of the private endpoint as json
$pe[0] | json
#>
function Get-PrivateEndpoint {
    [CmdletBinding()]
    param (
        [Alias('e')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByEndpoint')]
        [string]$PrivateEndpoint,

        [Alias('n')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByConnection')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByVNet')]
        [string]$VirtualNetwork,

        [Parameter(ParameterSetName = 'ByVNet')]
        [ValidateScript({ [System.Net.IPAddress]::TryParse($_, [ref]$null) }, ErrorMessage = 'Not a valid IP address.')]
        [string]$IP,

        [Parameter(Mandatory, ParameterSetName = 'ByConnection')]
        [Parameter(Mandatory, ParameterSetName = 'ByResource')]
        [string]$Resource
    )

    begin {
        # determine verbosity level
        $isVerbose = $PSBoundParameters.Verbose ? $true : $false

        # reset vnet variable
        $vnet = $null

        # get VNet and resource details based on the parameter set
        Show-LogContext "ParameterSetName: $($PsCmdlet.ParameterSetName)" -Level VERBOSE
        switch -Regex ($PsCmdlet.ParameterSetName) {
            '^(ByConnection|ByVNet)$' {
                # get the virtual network details
                $split = $VirtualNetwork.Split('/')
                $vnet = if ($split.Count -eq 2) {
                    Get-VirtualNetwork -VirtualNetwork $VirtualNetwork -Verbose:$isVerbose
                } else {
                    Get-VirtualNetwork -VirtualNetwork $VirtualNetwork -AzGraphResource -Verbose:$isVerbose
                }
                # if more than one virtual network found with the specified name, prompt the user to select one
                if ($vnet.Count -gt 1) {
                    $msg = "More than one virtual network found with the specified name ($VirtualNetwork)."
                    $idx = $vnet | Select-Object subscription, resourceGroup | Get-ArrayIndexMenu -Message $msg
                    $vnet = $vnet[$idx]
                } elseif ($vnet.Count -eq 0) {
                    Show-LogContext "no virtual network found ($VirtualNetwork)" -Level ERROR
                    exit 1
                }

                if ($vnet) {
                    if ($split.Count -eq 2) {
                        $subnetId = ($vnet.properties.subnets).Where({ $_.name -eq $split[1] }).id
                        if (-not $subnetId) {
                            Write-Warning "Subnet `e[4m$($split[1])`e[24m doesn't exist in the `e[4m$($split[0])`e[24m VNet."
                            return
                        }
                    }
                    Show-LogContext "Found VNet: $($vnet.id)" -Level VERBOSE
                } else {
                    Write-Warning "Virtual network doesn't exist ($VirtualNetwork)."
                    return
                }
            }
            '^(ByConnection|ByResource)$' {
                Show-LogContext 'looking for resource...' -Level VERBOSE
                $targetId = try {
                    Get-AzGraphResource -ResourceId $Resource | Select-Object -ExpandProperty id
                } catch {
                    $peParam = @{
                        ResourceName = $Resource
                        ExcludeTypes = @(
                            'microsoft.network/virtualnetworks'
                            'microsoft.network/privateendpoints'
                            'microsoft.network/privatednszones/virtualnetworklinks'
                        )
                    }
                    Get-AzGraphResourceByName @peParam | Select-Object -ExpandProperty id
                }
                if ($targetId) {
                    Show-LogContext "Found resource: $targetId" -Level VERBOSE
                } else {
                    Write-Warning "Resource doesn't exist ($Resource)."
                    return
                }
            }
        }

        function Get-Query {
            [CmdletBinding()]
            param (
                [string]$PrivateEndpointId,

                [string]$PrivateEndpointName,

                [string]$TargetId,

                [string]$SubNetId,

                [string]$VNetId
            )

            # build the kusto query string to get private endpoints with nic properties
            $builder = [System.Text.StringBuilder]::new()
            $builder.AppendLine("Resources`n| where type =~ 'Microsoft.Network/privateEndpoints'") | Out-Null
            if ($PrivateEndpointId) {
                $builder.AppendLine("`tand id =~ '$PrivateEndpointId'") | Out-Null
            } elseif ($PrivateEndpointName) {
                $builder.AppendLine("`tand name =~ '$PrivateEndpointName'") | Out-Null
            } elseif ($SubNetId) {
                $builder.AppendLine("`tand properties.subnet.id =~ '$SubNetId'") | Out-Null
            } elseif ($VNetId) {
                $builder.AppendLine("`tand properties.subnet.id startswith '$VNetId/subnets/'") | Out-Null
            }
            if ($TargetId) {
                $builder.AppendLine("`tand properties.privateLinkServiceConnections[0].properties.privateLinkServiceId =~ '$TargetId'") | Out-Null
            }
            $builder.AppendLine('| extend nicId = tolower(properties.networkInterfaces[0].id)') | Out-Null
            $builder.AppendLine('| join kind=leftouter (') | Out-Null
            $builder.AppendLine("`tResources`n`t| where type =~ 'Microsoft.Network/networkInterfaces'") | Out-Null
            $builder.AppendLine("`t| project nicId = tolower(id), ipConfigurations = properties.ipConfigurations") | Out-Null
            $builder.AppendLine(') on nicId') | Out-Null
            $builder.AppendLine('| join kind=leftouter (') | Out-Null
            $builder.AppendLine("`tResourceContainers`n`t| where type =~ 'microsoft.resources/subscriptions'") | Out-Null
            $builder.AppendLine("`t| project subscription=name, subscriptionId") | Out-Null
            $builder.AppendLine(') on subscriptionId') | Out-Null
            $builder.Append('| project id, name, type, tenantId, kind, location, resourceGroup, subscriptionId, subscription, sku, identity, tags, properties, ipConfigurations') | Out-Null

            return $builder.ToString()
        }
    }

    process {
        # get private endpoint(s) based on the parameter set
        switch ($PsCmdlet.ParameterSetName) {
            ByEndpoint {
                Show-LogContext 'getting private endpoint by name/id...' -Level VERBOSE
                $queryParam = if ($PrivateEndpoint -match '^\/subscriptions\/[0-9a-f-]+\/resourceGroups\/[\w-]+\/providers\/Microsoft\.Network\/privateEndpoints\/([\w-]+)$') {
                    @{ PrivateEndpointId = $PrivateEndpoint }
                } else {
                    @{ PrivateEndpointName = $PrivateEndpoint }
                }
            }
            ByConnection {
                Show-LogContext 'getting private endpoint by connection...' -Level VERBOSE
                if ($vnet -and $targetId) {
                    $queryParam = @{ TargetId = $targetId }
                    if ($subnetId) {
                        $queryParam.SubnetId = $subnetId
                    } else {
                        $queryParam.VNetId = $vnet.id
                    }
                } else {
                    $null
                }
                break
            }
            ByVNet {
                Show-LogContext 'getting private endpoint by VNet...' -Level VERBOSE
                $queryParam = if ($vnet) {
                    if ($subnetId) {
                        @{ SubnetId = $subnetId }
                    } else {
                        @{ VNetId = $vnet.id }
                    }
                } else {
                    $null
                }
                break
            }
            ByResource {
                Show-LogContext 'getting private endpoint by resource...' -Level VERBOSE
                $queryParam = if ($targetId) {
                    @{ TargetId = $targetId }
                } else {
                    $null
                }
                break
            }
        }
        $pe = if ($queryParam) {
            $query = Get-Query @queryParam
            $peParam = @{
                Query   = $query
                Verbose = $PSBoundParameters.Verbose ? $true : $false
            }
            if ($vnet) {
                $peParam.SubscriptionId = $vnet.subscriptionId
            }
            Invoke-AzGraph @peParam | ForEach-Object {
                $primaryIP = $_.ipConfigurations.properties.Where({ $_.primary }).privateIPAddress
                $_ | Add-Member -NotePropertyName 'primaryIP' -NotePropertyValue $primaryIP -PassThru
            }
        } else {
            $null
        }

        # add ipConfigurations to the private endpoint networkInterfaces property
        if ($pe -and ($PSBoundParameters.IP)) {
            $pe = $pe.Where({ $IP -in $_.ipConfigurations.properties.privateIPAddress })
        }
    }

    end {
        Show-LogContext "Found $($pe.Count) private endpoints." -Level VERBOSE
        return $pe
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
        } elseif ($params.InFile) {
            Write-Verbose "Body`n$(Get-Content $params.InFile | Join-String -Separator "`n")" -Verbose
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
