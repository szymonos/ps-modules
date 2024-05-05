<#
.SYNOPSIS
Get list of kubernetes namespaces for the function ArgumentCompleter attribute.
#>
function ArgK8sGetContexts {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # kubectl command string
    $cmnd = 'kubectl config view --output json | ConvertFrom-Json'

    # get namespaces
    [string[]]$possibleValues = (Invoke-Expression $cmnd).contexts.name

    # return matching namespaces
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Get list of kubernetes namespaces for the function ArgumentCompleter attribute.
#>
function ArgK8sGetNamespaces {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # kubectl command string
    $cmnd = 'kubectl get namespaces --output json | ConvertFrom-Json'

    # get namespaces
    [string[]]$possibleValues = (Invoke-Expression $cmnd).items.Where({ $_.status.phase -eq 'Active' }).metadata.name

    # return matching namespaces
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Get list of kubernetes pods for the function ArgumentCompleter attribute.
#>
function ArgK8sGetPods {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # build kubectl command string
    $sb = [System.Text.StringBuilder]::new('kubectl get pods --output json')
    if ($fakeBoundParameters.ContainsKey('Namespace')) {
        $sb.Append(" --namespace $($fakeBoundParameters.Namespace)") | Out-Null
    }
    $sb.Append(' | ConvertFrom-Json') | Out-Null
    # get command string
    $cmnd = $sb.ToString()

    # get pods
    [string[]]$possibleValues = (Invoke-Expression $cmnd).items.Where({ $_.status.phase -eq 'Running' }).metadata.name

    # return matching pods
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Get list of pod containers for the function ArgumentCompleter attribute.
#>
function ArgK8sGetPodContainers {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    if ($fakeBoundParameters.ContainsKey('Pod')) {
        # build kubectl command string
        $sb = [System.Text.StringBuilder]::new("kubectl get pods $($fakeBoundParameters.Pod) --output json")
        if ($fakeBoundParameters.ContainsKey('Namespace')) {
            $sb.Append(" --namespace $($fakeBoundParameters.Namespace)") | Out-Null
        }
        $sb.Append(' | ConvertFrom-Json') | Out-Null
        # get command string
        $cmnd = $sb.ToString()

        # get pod containers
        [string[]]$possibleValues = (Invoke-Expression $cmnd).spec.containers.name

        # # return matching containers
        $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
    }
}
