<#
.SYNOPSIS
Class of Az module compatible Azure object.
#>
class AzResource {
    [string]$ResourceId
    [string]$Id
    [string]$Kind
    [string]$Location
    [string]$ResourceName
    [string]$Name
    [string]$ResourceGroupName
    [string]$ResourceType
    [string]$Type
    [guid]$SubscriptionId
    [string]$SubscriptionName
    [psobject]$Sku
    [psobject]$Properties
    [psobject]$Tags
    [psobject]$Identity

    # constructors
    AzResource () { }

    AzResource ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 9) {
                $this.ResourceId = $id
                $this.Id = $this.ResourceId
                $this.ResourceName = $idSplit[8]
                $this.Name = $this.ResourceName
                $this.ResourceGroupName = $idSplit[4]
                $this.ResourceType = "$($idSplit[6])/$($idSplit[7])"
                $this.Type = $this.ResourceType
                $this.SubscriptionId = $idSplit[2]
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzResource ([guid]$subscriptionId, [string]$resourceGroupName, [string]$resourceType, [string]$name) {
        $this.ResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/$resourceType/$name"
        $this.Id = $this.ResourceId
        $this.ResourceName = $name
        $this.Name = $this.ResourceName
        $this.ResourceGroupName = $resourceGroupName
        $this.ResourceType = $resourceType
        $this.Type = $this.ResourceType
        $this.SubscriptionId = $subscriptionId
    }

    AzResource ([AzGraphResource]$obj) {
        $this.ResourceId = $obj.id
        $this.Id = $this.ResourceId
        $this.Kind = $obj.kind
        $this.Location = $obj.location
        $this.ResourceName = $obj.name
        $this.Name = $this.ResourceName
        $this.ResourceGroupName = $obj.resourceGroup
        $this.ResourceType = $obj.type
        $this.Type = $this.ResourceType
        $this.SubscriptionId = $obj.subscriptionId
        $this.SubscriptionName = $obj.subscription
        $this.Sku = $obj.sku
        $this.Properties = $obj.properties
        $this.Tags = $obj.tags
        $this.Identity = $obj.identity
    }

    [string] GetSubscriptionName () {
        $this.SubscriptionName = (Get-AzGraphSubscriptions -SubscriptionId $this.SubscriptionId).name

        return $this.SubscriptionName
    }
}
# Specify AzResource DefaultDisplayPropertySet
Update-TypeData -TypeName 'AzResource' -DefaultDisplayPropertySet 'Name', 'ResourceGroupName', 'ResourceType', 'SubscriptionId', 'ResourceId' -ErrorAction SilentlyContinue

<#
.SYNOPSIS
Class of Az.ResourceGraph compatible Azure object.
#>
class AzGraphResource {
    [string]$id
    [string]$kind
    [string]$location
    [string]$name
    [string]$resourceGroup
    [string]$type
    [guid]$subscriptionId
    [string]$subscription
    [guid]$tenantId
    [psobject]$sku
    [psobject]$properties
    [psobject]$tags
    [psobject]$identity
    [string]$ResourceId

    # constructors
    AzGraphResource () { }

    AzGraphResource ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 9) {
                $this.id = $id
                $this.name = $idSplit[8]
                $this.resourceGroup = $idSplit[4]
                $this.type = "$($idSplit[6])/$($idSplit[7])"
                $this.subscriptionId = $idSplit[2]
                $this.ResourceId = $this.id
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzGraphResource ([guid]$SubscriptionId, [string]$ResourceGroup, [string]$Type, [string]$Name) {
        $this.id = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/$Type/$Name"
        $this.name = $Name
        $this.resourceGroup = $ResourceGroup
        $this.type = $Type
        $this.subscriptionId = $SubscriptionId
        $this.ResourceId = $this.id
    }

    AzGraphResource ([PSCustomObject]$obj) {
        $this.id = $obj.id
        $this.kind = $obj.kind
        $this.location = $obj.location
        $this.name = $obj.name
        $this.resourceGroup = $obj.resourceGroup
        $this.type = $obj.type
        $this.subscriptionId = $obj.subscriptionId
        $this.subscription = $obj.subscription
        $this.tenantId = $obj.tenantId
        $this.sku = $obj.sku
        $this.properties = $obj.properties
        $this.tags = $obj.tags
        $this.identity = $obj.identity
        $this.ResourceId = $this.id
    }

    [string] GetSubscriptionName () {
        $this.subscription = (Get-AzGraphSubscriptions -SubscriptionId $this.subscriptionId).name

        return $this.subscription
    }
}
# Specify AzGraphResource DefaultDisplayPropertySet
Update-TypeData -TypeName 'AzGraphResource' -DefaultDisplayPropertySet 'name', 'resourceGroup', 'type', 'subscriptionId', 'id' -ErrorAction SilentlyContinue
