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

    # get namespaces
    [string[]]$possibleValues = (kubectl config view --output json | ConvertFrom-Json).contexts.name

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

    # get namespaces
    [string[]]$possibleValues = (kubectl get namespaces --output json | ConvertFrom-Json).items `
    | Where-Object { $_.status.phase -eq 'Active' } `
    | Select-Object -ExpandProperty metadata `
    | Select-Object -ExpandProperty name

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

    # calculate get pods command depending if namespace has been provided
    $cmnd = if ($fakeBoundParameters.ContainsKey('Namespace')) {
        { kubectl get pods --namespace $($fakeBoundParameters.Namespace) --output json }
    } else {
        { kubectl get pods --output json }
    }

    # get pods
    [string[]]$possibleValues = (Invoke-Command $cmnd | ConvertFrom-Json).items `
    | Where-Object { $_.status.phase -eq 'Running' } `
    | Select-Object -ExpandProperty metadata `
    | Select-Object -ExpandProperty name

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

    # build kubectl command
    if ($fakeBoundParameters.ContainsKey('Pod')) {
        # (kubectl get pods $($fakeBoundParameters.Pod) --output json | ConvertFrom-Json).spec.containers.name
        # build kubectl command
        $sb = [System.Text.StringBuilder]::new("kubectl get pods $($fakeBoundParameters.Pod) --output json")
        if ($fakeBoundParameters.ContainsKey('Namespace')) {
            $sb.Append(" --namespace $($fakeBoundParameters.Namespace)") | Out-Null
        }
        $sb.Append(' | ConvertFrom-Json') | Out-Null

        # @($sb.ToString())

        # get pod containers
        [string[]]$possibleValues = (Invoke-Expression $sb.ToString()).spec.containers.name

        # # return matching containers
        $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
    } else {
        @('ala', 'ma', 'kota')
    }
}
