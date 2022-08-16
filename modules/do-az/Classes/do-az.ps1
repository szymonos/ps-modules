<#
.SYNOPSIS
Class of Az module compatible Azure object.
#>
class AzResource {
    [string]$Name
    [string]$ResourceGroupName
    [guid]$SubscriptionId
    [string]$SubscriptionName
    [string]$ResourceType
    [string]$ResourceId

    # constructors
    AzResource () { }

    AzResource ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 9) {
                $this.Name = $idSplit[8]
                $this.ResourceGroupName = $idSplit[4]
                $this.SubscriptionId = $idSplit[2]
                $this.ResourceType = "$($idSplit[6])/$($idSplit[7])"
                $this.ResourceId = $id
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzResource ([PSCustomObject]$obj) {
        $this.Name = $obj.Name
        $this.ResourceGroupName = $obj.ResourceGroupName
        $this.subscriptionId = $obj.ResourceId.Split('/')[2]
        $this.ResourceType = $obj.ResourceType
        $this.ResourceId = $obj.ResourceId
    }

    AzResource ([guid]$subscriptionId, [string]$resourceGroupName, [string]$resourceType, [string]$name) {
        $this.Name = $name
        $this.ResourceGroupName = $resourceGroupName
        $this.SubscriptionId = $subscriptionId
        $this.ResourceType = $resourceType
        $this.ResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/$resourceType/$name"
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
    [string]$name
    [string]$resourceGroup
    [guid]$subscriptionId
    [string]$subscription
    [string]$type
    [string]$id

    # constructors
    AzGraphResource () { }

    AzGraphResource ([string]$Id) {
        if ($Id) {
            $idSplit = $Id.Split('/')
            if ($idSplit.Count -eq 9) {
                $this.name = $idSplit[8]
                $this.resourceGroup = $idSplit[4]
                $this.subscriptionId = $idSplit[2]
                $this.type = "$($idSplit[6])/$($idSplit[7])"
                $this.id = $Id
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzGraphResource ([PSCustomObject]$obj) {
        $this.name = $obj.name
        $this.resourceGroup = $obj.resourceGroup
        $this.subscriptionId = $obj.subscriptionId
        $this.subscription = $obj.subscription
        $this.type = $obj.type
        $this.id = $obj.id
    }

    AzGraphResource ([guid]$SubscriptionId, [string]$ResourceGroup, [string]$Type, [string]$Name) {
        $this.name = $Name
        $this.resourceGroup = $ResourceGroup
        $this.subscriptionId = $SubscriptionId
        $this.type = $Type
        $this.id = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/$Type/$Name"
    }

    [string] GetSubscriptionName () {
        $this.subscription = (Get-AzGraphSubscriptions -SubscriptionId $this.subscriptionId).name

        return $this.subscription
    }
}
