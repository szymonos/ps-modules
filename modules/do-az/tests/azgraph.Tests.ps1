# Import the module containing the functions
Import-Module "$PWD/modules/do-az/do-az.psd1"

# Mock external dependencies
Mock -CommandName Search-AzGraph -MockWith { return @() }
Mock -CommandName Connect-AzContext -MockWith { return [PSCustomObject]@{ Tenant = [PSCustomObject]@{ Id = 'mock-tenant-id' } } }
Mock -CommandName Invoke-CommandRetry -MockWith { param($scriptBlock) & $scriptBlock }

Describe 'Invoke-AzGraph' {
    It 'Should execute with default parameters' {
        $result = Invoke-AzGraph -Query 'mock-query'
        $result | Should -BeOfType 'System.Collections.Generic.List[PSCustomObject]'
    }

    It 'Should execute with JSON output' {
        $result = Invoke-AzGraph -Query 'mock-query' -JsonOutput
        $result | Should -BeOfType 'String'
    }
}

Describe 'Get-AzGraphSubscription' {
    It 'Should construct query for ManagementGroup' {
        $result = Get-AzGraphSubscription -ManagementGroup 'mock-mgmt-group'
        $result | Should -BeOfType 'AzGraphSubscription[]'
    }

    It 'Should construct query for SubscriptionId' {
        $result = Get-AzGraphSubscription -SubscriptionId 'mock-subscription-id'
        $result | Should -BeOfType 'AzGraphSubscription[]'
    }
}

Describe 'Get-AzGraphResourceGroup' {
    It 'Should construct query for ResourceId' {
        $result = Get-AzGraphResourceGroup -ResourceId 'mock-resource-id'
        $result | Should -BeOfType 'AzGraphResourceGroup[]'
    }

    It 'Should construct query for ResourceGroupName' {
        $result = Get-AzGraphResourceGroup -ResourceGroupName 'mock-rg-name'
        $result | Should -BeOfType 'AzGraphResourceGroup[]'
    }
}

Describe 'Get-AzGraphResourceGroupByName' {
    It 'Should select resource group when multiple results are returned' {
        Mock -CommandName Get-AzGraphResourceGroup -MockWith { return @(1, 2) }
        Mock -CommandName Get-ArrayIndexMenu -MockWith { return 0 }
        $result = Get-AzGraphResourceGroupByName -ResourceGroupName 'mock-rg-name'
        $result | Should -Be 1
    }
}

Describe 'Get-AzGraphResource' {
    It 'Should construct query for ResourceId' {
        $result = Get-AzGraphResource -ResourceId 'mock-resource-id'
        $result | Should -BeOfType 'AzGraphResource[]'
    }

    It 'Should construct query for ResourceGroupName' {
        $result = Get-AzGraphResource -ResourceGroupName 'mock-rg-name'
        $result | Should -BeOfType 'AzGraphResource[]'
    }
}

Describe 'Get-AzGraphResourceByName' {
    It 'Should exclude specified resource types' {
        $result = Get-AzGraphResourceByName -ResourceName 'mock-resource-name' -ExcludeTypes 'type1', 'type2'
        $result | Should -BeOfType 'AzGraphResource[]'
    }

    It 'Should select resource when multiple results are returned' {
        Mock -CommandName Get-AzGraphResource -MockWith { return @(1, 2) }
        Mock -CommandName Get-ArrayIndexMenu -MockWith { return 0 }
        $result = Get-AzGraphResourceByName -ResourceName 'mock-resource-name'
        $result | Should -Be 1
    }
}
