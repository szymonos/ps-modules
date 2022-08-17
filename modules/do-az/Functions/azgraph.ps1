$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Generic Search-AzGraph request.
.PARAMETER Query
Kusto query.
.PARAMETER SubscriptionId
Optional subscription id.
#>
function Invoke-AzGraph {
    [CmdletBinding()]
    param (
        [Alias('q')]
        [Parameter(Mandatory)]
        [string]$Query,

        [Alias('s')]
        [string]$SubscriptionId
    )

    begin {
        $param = @{ First = 100 }
        if ($PSBoundParameters.SubscriptionId) {
            $param.Subscription = $SubscriptionId
        }

        $result = [Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        $response = $null
        do {
            $response = Invoke-CommandRetry {
                Search-AzGraph @param -Query $Query -SkipToken $response.SkipToken
            }
            $response.ForEach({ $result.Add($_) })
        } while ($response.SkipToken)
    }

    end {
        return $result
    }
}

<#
.SYNOPSIS
Get Azure Subscriptions using AzGraph.
.PARAMETER SubscriptionId
Subscription ID.
.PARAMETER Condition
Optional query condition.
#>
function Get-AzGraphSubscriptions {
    [CmdletBinding()]
    param (
        [Alias('s')]
        [string]$SubscriptionId,

        [Alias('c')]
        [string]$Condition
    )

    # build filter
    $filter = $PSBoundParameters.Condition ? "`n`tand $Condition" : ''

    # splat parameters
    $param = @{
        Query = @"
ResourceContainers
| where type == 'microsoft.resources/subscriptions'$filter
| project id, name, type, tenantId, subscriptionId, properties
"@
    }
    if ($PSBoundParameters.SubscriptionId) {
        $param.Subscription = $SubscriptionId
    }

    return Invoke-AzGraph @param
}

<#
.SYNOPSIS
Get resources group(s) in specified subscription.
.PARAMETER SubscriptionId
Subscription ID.
.PARAMETER ResourceGroupName
Optional resource group name.
.PARAMETER Condition
Optional query condition.#>
function Get-AzGraphResourceGroups {
    [CmdletBinding()]
    param (
        [Alias('s')]
        [string]$SubscriptionId,

        [Alias('g')]
        [string]$ResourceGroupName,

        [Alias('c')]
        [string]$Condition
    )

    # build filter
    $filter = $PSBoundParameters.ResourceGroupName ? "`n`tand name =~ '$ResourceGroupName'" : ''
    $filter += $PSBoundParameters.Condition ? "`n`tand $Condition" : ''

    # splat parameters
    $param = @{
        Query = @"
ResourceContainers
| where type == 'microsoft.resources/subscriptions/resourcegroups'$filter
| join kind=leftouter (
    ResourceContainers
    | where type =~ "microsoft.resources/subscriptions"
    | project subscription=name, subscriptionId
    ) on subscriptionId
| project id, name, type, tenantId, location, resourceGroup, subscriptionId, subscription, properties, tags
"@
    }
    if ($PSBoundParameters.SubscriptionId) {
        $param.Subscription = $SubscriptionId
    }

    return Invoke-AzGraph @param
}

<#
.SYNOPSIS
Get resources using AzGraph.
.PARAMETER SubscriptionId
Subscription ID.
.PARAMETER ResourceGroupName
Resource group name.
.PARAMETER Condition
Optional query condition.#>
function Get-AzGraphResources {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType([AzGraphResource[]])]
    param (
        [Alias('s')]
        [Parameter(Mandatory, ParameterSetName = 'Group')]
        [Parameter(ParameterSetName = 'Type')]
        [Parameter(Mandatory, ParameterSetName = 'GroupType')]
        [string]$SubscriptionId,

        [Alias('i')]
        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [string]$ResourceId,

        [Alias('g')]
        [Parameter(Mandatory, ParameterSetName = 'Group')]
        [Parameter(Mandatory, ParameterSetName = 'GroupType')]
        [string]$ResourceGroupName,

        [Alias('t')]
        [Parameter(Mandatory, ParameterSetName = 'Type')]
        [Parameter(Mandatory, ParameterSetName = 'GroupType')]
        [ValidateScript({ $_ -match '\w+\.\w+/\w+' }, ErrorMessage = "`e[1;4m{0}`e[22;24m is not valid type")]
        [string]$ResourceType,

        [Alias('c')]
        [Parameter(Mandatory, ParameterSetName = 'Condition')]
        [Parameter(ParameterSetName = 'Group')]
        [Parameter(ParameterSetName = 'Type')]
        [string]$Condition
    )

    begin {
        # initialize parameter splat
        $param = @{}

        # build filter
        if ($PSBoundParameters.ResourceId) {
            $filter = $PSBoundParameters.ResourceId ? "id =~ '$ResourceId'" : ''
            $param.Subscription = ([AzResource]$PSBoundParameters.ResourceId).SubscriptionId
        } else {
            $filter = $PSBoundParameters.ResourceGroupName ? "resourceGroup =~ '$ResourceGroupName'" : ''
            $filter += ($PSBoundParameters.ResourceGroupName -and $PSBoundParameters.ResourceType) ? "`n`tand " : ''
            $filter += $PSBoundParameters.ResourceType ? "type =~ '$ResourceType'" : ''
            $filter += ($PSBoundParameters.ResourceGroupName -or $PSBoundParameters.ResourceType) -and $PSBoundParameters.Condition ? "`n`tand " : ''
            $filter += $PSBoundParameters.Condition ? $Condition : ''
        }

        # splat parameters
        $param.Query = @"
Resources
| where $filter
| join kind=leftouter (
    ResourceContainers
    | where type =~ "microsoft.resources/subscriptions"
    | project subscription=name, subscriptionId
    ) on subscriptionId
| project id, name, type, tenantId, kind, location, resourceGroup, subscriptionId, subscription, sku, properties, tags, identity
"@
        if ($PSBoundParameters.SubscriptionId) {
            $param.Subscription = $SubscriptionId
        }
    }

    process {
        $obj = [AzGraphResource[]](Invoke-AzGraph @param)
    }

    end {
        return $obj
    }
}

<#
.SYNOPSIS
Get Azure resource object by name and type.
.PARAMETER ResourceName
Azure Resource Name
.PARAMETER ResourceType
Azure Resource Type
#>
function Get-AzGraphResourceByName {
    [CmdletBinding()]
    [OutputType([AzGraphResource])]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [Parameter(Mandatory, ParameterSetName = 'ByType')]
        [Parameter(Mandatory, ParameterSetName = 'ByCondition')]
        [string]$ResourceName,

        [Parameter(Mandatory, ParameterSetName = 'ByType')]
        [string]$ResourceType,

        [Parameter(Mandatory, ParameterSetName = 'ByCondition')]
        [ValidateScript({ $false -notin $_.ForEach{ $_ -match '\w+\.\w+/\w+' } }, ErrorMessage = "`e[1;4m{0}`e[22;24m is not valid type")]
        [string[]]$ExcludeTypes
    )

    begin {
        $param = @{
            Condition = "name =~ '$ResourceName'"
        }
        if ($ResourceType) {
            $param.ResourceType = $ResourceType
        }
        if ($ExcludeTypes) {
            $typesList = $ExcludeTypes.ForEach{ "`"$_`"" } -join ', '
            $param.Condition += " and type !in~ ($typesList)"
        }
    }

    process {
        $resource = Get-AzGraphResources @param | Sort-Object subscription, resourceGroup, type
        # select resource if query returned more than one result
        if ($resource.Count -gt 1) {
            Write-Warning 'Found more than one resource matching the criteria'
            $array = if ($ResourceType) {
                $resource | Select-Object resourceGroup, subscription
            } else {
                $resource | Select-Object type, resourceGroup, subscription
            }
            $Message = "Select object from provided 'Resource $($ResourceType ? '' : 'Type | ')Group | Subscription'"
            $i = Get-ArrayIndexMenu -Array $array -Message $Message
            $resource = $resource[$i]
        }
    }

    end {
        return $resource
    }
}
