<#
.SYNOPSIS
Get list of kubectl config clusters for the function ArgumentCompleter attribute.
#>
function ArgK8sGetClusters {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # get clusters
    $cmdArgs = @(
        'config', 'view'
        '--output', 'json'
    )
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).clusters.name

    # return matching clusters
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Get list of kubectl config contexts for the function ArgumentCompleter attribute.
#>
function ArgK8sGetContexts {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # get contexts
    $cmdArgs = @(
        'config', 'view'
        '--output', 'json'
    )
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).contexts.name

    # return matching contexts
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
    $cmdArgs = @(
        'get', 'namespaces'
        '--field-selector=status.phase=Active'
        '--output', 'json'
    )
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).items.metadata.name

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
    $cmdArgs = [System.Collections.Generic.List[string]]::new()
    $cmdArgs.AddRange([string[]]@('get', 'pods', '--field-selector=status.phase=Running'))
    if ($fakeBoundParameters.ContainsKey('Namespace')) {
        $cmdArgs.AddRange([string[]]@('--namespace', $fakeBoundParameters.Namespace))
    }
    $cmdArgs.AddRange([string[]]@('--output', 'json'))
    # get pods
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).items.metadata.name

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
        $cmdArgs = [System.Collections.Generic.List[string]]::new()
        $cmdArgs.AddRange([string[]]@('get', 'pod', $fakeBoundParameters.Pod))
        if ($fakeBoundParameters.ContainsKey('Namespace')) {
            $cmdArgs.AddRange([string[]]@('--namespace', $fakeBoundParameters.Namespace))
        }
        $cmdArgs.AddRange([string[]]@('--output', 'json'))
        # get pod containers
        [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).spec.containers.name

        # # return matching containers
        $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
    }
}


<#
.SYNOPSIS
Get list of kubernetes secrets for the function ArgumentCompleter attribute.
#>
function ArgK8sGetSecrets {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # build kubectl command string
    $cmdArgs = [System.Collections.Generic.List[string]]::new()
    $cmdArgs.AddRange([string[]]@('get', 'secrets'))
    if ($fakeBoundParameters.ContainsKey('Namespace')) {
        $cmdArgs.AddRange([string[]]@('--namespace', $fakeBoundParameters.Namespace))
    }
    $cmdArgs.AddRange([string[]]@('--output', 'json'))
    # get pods
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).items.metadata.name

    # return matching pods
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Complete arguments of the alias functions using the kubectl built-in completion (kubectl __complete).
#>
function ArgK8sKubectlComplete {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    $cmd = Get-Command $commandName
    # kubectl arguments baked into the alias function, e.g. @('get', 'deployment')
    $aliasArgs = $cmd.ScriptBlock.Ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.ArrayExpressionAst]
        }, $true)[0].SafeGetValue()
    # words typed after the alias, without the word being completed
    $elements = $commandAst.CommandElements | Select-Object -Skip 1
    if ($wordToComplete) { $elements = $elements | Select-Object -SkipLast 1 }
    # drop the parameters PowerShell binds to the function itself (-WhatIf, -ErrorAction Stop)
    # with their values; a word that resolves to none of them is passed on to kubectl
    $typed = [System.Collections.Generic.List[string]]::new()
    $skipValue = $false
    foreach ($element in $elements) {
        if ($skipValue) { $skipValue = $false; continue }
        if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
            $param = try { $cmd.ResolveParameter($element.ParameterName) } catch { $null }
            if ($param) {
                $skipValue = -not $param.SwitchParameter -and -not $element.Argument
                continue
            }
        }
        # kubectl gets the literal value, not the quoted source text
        $typed.Add($element -is [System.Management.Automation.Language.StringConstantExpressionAst] ? $element.Value : $element.Extent.Text)
    }
    # PowerShell passes a quoted word with its quotes, e.g. 'pre'
    $word = $wordToComplete.Trim("'", '"')

    # output: one 'value<TAB>description' per line, followed by the ':<directive>' line
    $lines = @(& kubectl __complete @aliasArgs @typed $word 2>$null)
    $directive = [int]($lines[-1] -replace ':')
    # file extension (8) or directory (16) filter: complete paths, keeping directories
    # and only the files whose extension kubectl listed
    if ($directive -band 24) {
        $exts = @($lines | Select-Object -SkipLast 1)
        foreach ($item in Get-Item -Path "$word*" -Force -ErrorAction SilentlyContinue) {
            if ($item.PSIsContainer -or ($directive -band 8 -and $item.Extension.TrimStart('.') -in $exts)) {
                $path = Resolve-Path -Relative -LiteralPath $item.FullName
                $text = $path -match '\s' ? "'$path'" : $path
                $type = $item.PSIsContainer ? 'ProviderContainer' : 'ProviderItem'
                [System.Management.Automation.CompletionResult]::new($text, $item.Name, $type, $path)
            }
        }
        return
    }

    # kubectl answers '--flag=' completions with bare values
    $prefix = $word -match '^--?[^=]+=' ? $Matches[0] : ''
    foreach ($line in $lines | Select-Object -SkipLast 1) {
        $value, $desc = $line.Split("`t", 2)
        $value = $prefix + $value
        [System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', ($desc ? $desc : $value))
    }
}
