<#
.SYNOPSIS
Class of Az module compatible Azure object.
#>
class AzResource {
    [string]$ResourceId
    [string]$Name
    [string]$ResourceGroupName
    [string]$SubscriptionId
    [string]$SubscriptionName
    [string]$ResourceType
    [string]$Location
    [string]$Kind
    [psobject]$Sku
    [psobject]$Tags
    [psobject]$Properties
    [psobject]$Identity

    # constructors
    AzResource () { }

    AzResource ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 9) {
                $this.ResourceId = $id
                $this.Name = $idSplit[8]
                $this.ResourceGroupName = $idSplit[4]
                $this.SubscriptionId = $idSplit[2]
                $this.ResourceType = "$($idSplit[6])/$($idSplit[7])"
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzResource ([guid]$subscriptionId, [string]$resourceGroupName, [string]$resourceType, [string]$name) {
        $this.ResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/$resourceType/$name"
        $this.Name = $name
        $this.ResourceGroupName = $resourceGroupName
        $this.SubscriptionId = $subscriptionId
        $this.ResourceType = $resourceType
    }

    AzResource ([AzGraphResource]$obj) {
        $this.ResourceId = $obj.id
        $this.Name = $obj.name
        $this.ResourceGroupName = $obj.resourceGroup
        $this.SubscriptionId = $obj.subscriptionId
        $this.SubscriptionName = $obj.subscription
        $this.ResourceType = $obj.type
        $this.Location = $obj.location
        $this.Kind = $obj.kind
        $this.Sku = $obj.sku
        $this.Tags = $obj.tags
        $this.Properties = $obj.properties
        $this.Identity = $obj.identity
    }

    [string] GetSubscriptionName () {
        $this.SubscriptionName = (Get-AzGraphSubscriptions -SubscriptionId $this.SubscriptionId).name

        return $this.SubscriptionName
    }
}

<#
.SYNOPSIS
Class of Az.ResourceGraph compatible Azure object.
#>
class AzGraphResource {
    [string]$id
    [string]$name
    [string]$resourceGroup
    [guid]$subscriptionId
    [string]$subscription
    [string]$type
    [string]$location
    [guid]$tenantId
    [string]$kind
    [psobject]$sku
    [psobject]$tags
    [psobject]$properties
    [psobject]$identity

    # constructors
    AzGraphResource () { }

    AzGraphResource ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 9) {
                $this.id = $id
                $this.name = $idSplit[8]
                $this.resourceGroup = $idSplit[4]
                $this.subscriptionId = $idSplit[2]
                $this.type = "$($idSplit[6])/$($idSplit[7])"
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzGraphResource ([guid]$SubscriptionId, [string]$ResourceGroup, [string]$Type, [string]$Name) {
        $this.id = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/$Type/$Name"
        $this.name = $Name
        $this.resourceGroup = $ResourceGroup
        $this.subscriptionId = $SubscriptionId
        $this.type = $Type
    }

    AzGraphResource ([PSCustomObject]$obj) {
        $this.id = $obj.id
        $this.name = $obj.name
        $this.resourceGroup = $obj.resourceGroup
        $this.subscriptionId = $obj.subscriptionId
        $this.subscription = $obj.subscription
        $this.type = $obj.type
        $this.location = $obj.location
        $this.tenantId = $obj.tenantId
        $this.kind = $obj.kind
        $this.sku = $obj.sku
        $this.tags = $obj.tags
        $this.properties = $obj.properties
        $this.identity = $obj.identity
    }

    [string] GetSubscriptionName () {
        $this.subscription = (Get-AzGraphSubscriptions -SubscriptionId $this.subscriptionId).name

        return $this.subscription
    }
}
