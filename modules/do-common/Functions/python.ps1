<#
.SYNOPSIS
Add certificates from SSL chain to the certifi file.
#>
function Invoke-CertifiFixFromChain {
    [CmdletBinding()]
    param ()
    begin {
        $ErrorActionPreference = 'Stop'

        $cacertPaths = [System.Collections.Generic.HashSet[string]]::new()
        # get certifi/cacert.pem file path
        foreach ($package in @('certifi', 'pip')) {
            [string[]]$showFiles = pip show -f $package 2>$null
            if ($location = ($showFiles | Select-String '(?<=^Location: ).+$').Matches.Value) {
                if ($cacert = ($showFiles | Select-String '\S*\bcacert\.pem$').Matches.Value) {
                    $cacert.ForEach({ $cacertPaths.Add(([IO.Path]::Combine($location, $_))) | Out-Null })
                }
            }
        }
    }

    process {
        if ($cacertPaths) {
            # get intermediate and root certificates
            $chain = Invoke-CommandRetry {
                Get-Certificate 'www.python.org' -BuildChain | Select-Object -Skip 1
            }
            # check if root certificate from chain is installed in the system
            $rootCrts = Get-RootCertificates
            if ($chain[-1].Thumbprint -in $rootCrts.Thumbprint) {
                foreach ($path in $cacertPaths) {
                    Write-Verbose $path.Replace($HOME, '~')
                    $certifiCerts = ConvertFrom-PEM $path
                    # check if certs already added to cacert.pem
                    if ($certsToAdd = $chain.ForEach({ $_.Where({ $_.Thumbprint -notin $certifiCerts.Thumbprint }) })) {
                        # add certificates from chain to the certifi/cacert.pem
                        foreach ($cert in $certsToAdd) {
                            $msg = [string]::Join("`n",
                                "`e[1;92mThumbprint :`e[0m $($cert.Thumbprint)",
                                "`e[1;92mSubject    :`e[0m $($cert.Subject)",
                                "`e[1;92mIssuer     :`e[0m $($cert.Issuer)`n"
                            )
                            Write-Host $msg
                            $pem = "`n$(ConvertTo-PEM $cert -AddHeader)"
                            if ($IsLinux -and (Get-ChildItem $path).User -eq 'root') {
                                sudo pwsh -nop -noni -c "[IO.File]::AppendAllText('$path', '$pem')"
                            } else {
                                [IO.File]::AppendAllText($path, $pem)
                            }
                        }
                    } else {
                        Write-Verbose 'All certificates from TLS chain already added to the file.'
                    }
                }
            } else {
                Write-Error "Root certificate from TLS chain is not trusted ($($chain[-1].Subject))."
            }
        } else {
            Write-Verbose 'Certifi not found in the environment.'
            return
        }
    }
}

Set-Alias -Name fxcertpy -Value Invoke-CertifiFixFromChain


<#
.SYNOPSIS
Manage conda environments.
.PARAMETER Option
Select script action.
.PARAMETER CondaFile
Specify conda file to use.
#>
function Invoke-CondaSetup {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Option,

        [Alias('f')]
        [ValidateNotNullorEmpty()]
        [string]$YamlFile = 'conda.yaml',

        [switch]$CertificateFix
    )

    dynamicparam {
        if (@('activate', 'create', 'remove') -match "^$Option" -and -not $PSBoundParameters.CondaFile) {
            $paramDict = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

            $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
            $attributeCollection.Add([Management.Automation.ParameterAttribute]@{ Position = 1 })
            $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Environment', [string], $attributeCollection
            )
            $paramDict.Add('Environment', $dynParam)

            if ('create' -match "^$Option") {
                # dependencies dynamic parameter
                $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
                $attributeCollection.Add([Management.Automation.ParameterAttribute]@{ Position = 2 })
                $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new(
                    'Dependencies', [string[]], $attributeCollection
                )
                $paramDict.Add('Dependencies', $dynParam)
            }

            return $paramDict
        }
    }

    begin {
        try {
            Get-Item Env:/CONDA_EXE -ErrorAction Stop | Out-Null
        } catch {
            if (Test-Path $HOME/miniconda3/bin/conda) {
                Write-Warning "Conda not initialized.`n"
                [Console]::WriteLine(
                    [string]::Join("`n",
                        'Run the below command to add conda initialization to Powershell for the current user:',
                        "`e[1m& `"`$HOME/miniconda3/$($IsWindows ? 'Scripts/conda.exe' : 'bin/conda')`" init powershell`e[0m"
                    )
                )
                return
            } else {
                Write-Warning "Conda not installed.`n"
                [Console]::WriteLine('Run the below command(s) to install miniconda:')
                if ($IsWindows) {
                    [Console]::WriteLine("`e[1mwinget install --id Anaconda.Miniconda3`e[0m")
                } elseif ($IsLinux) {
                    [Console]::WriteLine(
                        [string]::Join("`n",
                            "`e[1mcurl -fsSLO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh",
                            "sh ./Miniconda3-latest-Linux-x86_64.sh -b -p `$HOME/miniconda3 && rm -f ./Miniconda3-latest-Linux-x86_64.sh`e[0m"
                        )
                    )
                } elseif ($IsMacOS) {
                    [Console]::WriteLine(
                        [string]::Join("`n",
                            "`e[1mcurl -fsSLO https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh",
                            "sh ./Miniconda3-latest-MacOSX-x86_64.sh -b -p `$HOME/miniconda3 && rm -f ./Miniconda3-latest-MacOSX-x86_64.sh`e[0m"
                        )
                    )
                }
                return
            }
        }
        if (-not $Option) {
            [Console]::WriteLine(
                [string]::Join("`n",
                    "Invoke-CondaSetup cmdlet manages conda environments.`n",
                    "usage: Invoke-CondaSetup [-Option] <string> [-YamlFile <String>] [-CertificateFix] [[-Environment] <string>] [[-Dependencies] <string[]>]`n",
                    'The following Options are available:',
                    "  `e[1;97mactivate`e[0m    Activate environment",
                    "  `e[1;97mclean`e[0m       Clean conda environment",
                    "  `e[1;97mcreate`e[0m      Create conda environment",
                    "  `e[1;97mdeactivate`e[0m  Deactivate environment",
                    "  `e[1;97menvs`e[0m        List environments",
                    "  `e[1;97mfix`e[0m         Fix self-signed certificates",
                    "  `e[1;97minfo`e[0m        Display current conda install info",
                    "  `e[1;97mlist`e[0m        List packages",
                    "  `e[1;97mremove`e[0m      Remove environment",
                    "  `e[1;97msetup`e[0m       Create/update environment",
                    "  `e[1;97mupdate`e[0m      Update conda`n"
                )
            )
            return
        }
        # evaluate Option parameter abbreviations
        $optSet = @('activate', 'clean', 'create', 'deactivate', 'envs', 'fix', 'info', 'list', 'remove', 'setup', 'update')
        $opt = $optSet -match "^$Option"
        if ($opt.Count -eq 0) {
            Write-Warning "Option parameter name '$Option' is invalid. Valid Option values are:`n`t $($optSet -join ', ')"
            break
        } elseif ($opt.Count -gt 1) {
            Write-Warning "Option parameter name '$Option' is ambiguous. Possible matches include: $($opt -join ', ')."
            break
        }

        # check for conda file
        if ($opt -in @('activate', 'remove', 'setup')) {
            if ($PSBoundParameters.Environment) {
                $envName = $PSBoundParameters.Environment
                $envExists = $true
            } elseif (Test-Path $YamlFile) {
                # get environment name
                $envName = (Select-String -Pattern '^name: +(\S+)' -Path $YamlFile).Matches.Groups.Where({ $_.Name -eq '1' }).Value
                $envExists = $envName -in (Get-CondaEnvironment).Name
            } else {
                Write-Warning "File `e[4m$YamlFile`e[24m not found"
                break
            }
            if ($envName) {
                # exit environment before proceeding
                Exit-CondaEnvironment
            }
        }
    }

    # *Execute option
    process {
        if ($CertificateFix -and $opt -in @('create', 'setup')) {
            $opt = $opt + 'fix'
        }
        switch ($opt) {
            activate {
                # *Activate environment
                if ($envExists) {
                    Enter-CondaEnvironment $envName
                } else {
                    Write-Host "`e[1;4m$envName`e[22;24m environment doesn't exist!"
                }
                continue
            }

            clean {
                # *Clean conda
                Invoke-Conda clean -y --all
                continue
            }

            create {
                # *Create conda environment
                $cmd = "Invoke-Conda create --name $($PSBoundParameters.Environment) --yes $($PSBoundParameters.Dependencies -join ' ')"
                Invoke-Expression $cmd
                Enter-CondaEnvironment $PSBoundParameters.Environment
            }

            deactivate {
                # *Clean conda
                Exit-CondaEnvironment
                continue
            }

            envs {
                # *List environments
                Invoke-Conda env list
                continue
            }

            info {
                # *Display current conda install information
                conda info | ForEach-Object {
                    if ($_ -match '\w : ') {
                        $header, $val = $_.Split(' : ')
                        Write-Host "`e[1;92m${header} : `e[0m${val}"
                    } else {
                        Write-Host $_
                    }
                }
                continue
            }

            list {
                # *List packages
                Invoke-Conda list
                continue
            }

            fix {
                # *Fix certificates
                Invoke-CertifiFixFromChain
                continue
            }

            remove {
                # *Remove environment
                if ($envName -eq 'base') {
                    Write-Host "Cannot remove `e[1;4mbase`e[22;24m environment!"
                } elseif ($envExists) {
                    Write-Host "Removing `e[1;4m$envName`e[22;24m environment."
                    Invoke-Conda env remove --name $envName
                } else {
                    Write-Host "`e[1;4m$envName`e[22;24m environment doesn't exist!"
                }
                continue
            }

            setup {
                if ($envExists) {
                    # *Create environment
                    Write-Host "`nEnvironment `e[1;4m$envName`e[22;24m already exist. Updating..."
                    Invoke-Conda env update --file $YamlFile --prune
                    Enter-CondaEnvironment $envName
                } else {
                    # *Update environment
                    Write-Host "Creating `e[1;4m$envName`e[22;24m environment."
                    Invoke-Conda env create --file $YamlFile
                    Enter-CondaEnvironment $envName
                }
                continue
            }

            update {
                # *Update conda
                Invoke-Conda update --name base --channel defaults conda --yes --update-all
                continue
            }

        }
    }
}

Set-Alias -Name ics -Value Invoke-CondaSetup


<#
.SYNOPSIS
Setup Python virtual environment in the project and much more...
.PARAMETER Option
Select script action.
.PARAMETER AppPath
Specify application path to be added by pypath.
#>
function Invoke-PySetup {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Option,

        [Alias('p')]
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$AppPath
    )

    begin {
        if (-not $Option) {
            [Console]::WriteLine(
                [string]::Join("`n",
                    "Invoke-PySetup cmdlet manages Python virtual environments.`n",
                    "usage: Invoke-PySetup [-Option] <string> [-AppPath <string>]`n",
                    'The following options are available:',
                    "  `e[1;97mactivate`e[0m    Activate virtual environment",
                    "  `e[1;97mclean`e[0m       Delete all cache folders",
                    "  `e[1;97mdeactivate`e[0m  Deactivate virtual environment",
                    "  `e[1;97mgetenv`e[0m      Get environment variables",
                    "  `e[1;97minstall`e[0m     Install requirements",
                    "  `e[1;97mlist`e[0m        List installed modules",
                    "  `e[1;97mpurge`e[0m       Purge pip cache",
                    "  `e[1;97mremove`e[0m      Remove python virtual environment",
                    "  `e[1;97msetenv`e[0m      Set environment variables",
                    "  `e[1;97msshkey`e[0m      Generate key pairs for SSH",
                    "  `e[1;97mssltrust`e[0m    Trust SSL connection to pypi.org",
                    "  `e[1;97mupdate`e[0m      Update installed python modules",
                    "  `e[1;97mvenv`e[0m        Setup python virtual environment`n"
                )
            )
            return
        }
        # evaluate Option parameter abbreviations
        $optSet = @('activate', 'clean', 'deactivate', 'getenv', 'install', 'list', 'purge', 'remove', 'setenv', 'sshkey', 'ssltrust', 'update', 'venv')
        $opt = $optSet -match "^$Option"
        if ($opt.Count -eq 0) {
            Write-Warning "Option parameter name '$Option' is invalid. Valid Option values are:`n`t $($optSet -join ', ')"
            break
        } elseif ($opt.Count -gt 1) {
            Write-Warning "Option parameter name '$Option' is ambiguous. Possible matches include: $($opt -join ', ')."
            break
        }

        # constants
        $VENV_DIR = '.venv'
        $GITIGNORE = 'https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore'

        # calculate script variables
        $req_files = [Collections.Generic.List[string]]::new([string[]]@('requirements.txt'))
        if ($AppPath) {
            $appReq = [IO.Path]::Combine($AppPath, 'requirements.txt')
            if (Test-Path $appReq) {
                $req_files.Add($appReq)
            }
        }
        $req = @{
            name  = $req_files[0]
            value = "black`nflake8`nipykernel`nnotebook`npydocstyle`npylint`npypath-magic`n"
        }
        $localSettings = [IO.Path]::Combine($AppPath, 'local.settings.json')
        $activateDir = [IO.Path]::Combine($VENV_DIR, ($IsWindows ? 'Scripts' : 'bin'))
        $activateScript = (Test-Path $activateDir) ? (Get-ChildItem -Path $activateDir -Filter 'activate.ps1').FullName : $null
        $venvCreated = $activateScript ? $true : $false
        $initScript = [IO.Path]::Combine('.vscode', 'init.ps1')

        # get environment variables from local.settings.json file
        if ($opt -in @('setenv', 'getenv')) {
            if (Test-Path $localSettings) {
                Write-Host "`e[96mUsing variables configured in local.settings.json.`e[0m"
                $envVars = (Get-Content ([IO.Path]::Combine($AppPath, 'local.settings.json')) | ConvertFrom-Json).Values
            } else {
                Write-Warning "File `e[3mlocal.settings.json`e[23m do not exist."
                break
            }
        }
    }

    process {
        switch ($opt) {
            # *Activate virtual environment.
            { $_ -in @('activate', 'update', 'venv') -and -not $env:VIRTUAL_ENV -and $venvCreated } {
                & $activateScript
                if ($opt -eq 'activate') {
                    break
                }
            }

            # *Deactivate virtual environment.
            { $_ -eq 'deactivate' -and $env:VIRTUAL_ENV } {
                deactivate
                break
            }

            # *Delete python virtual environment.
            remove {
                if ($env:VIRTUAL_ENV) {
                    deactivate
                }
                if (Test-Path $VENV_DIR) {
                    Write-Host "`e[96mDelete virtual environment.`e[0m"
                    Remove-Item $VENV_DIR -Recurse -Force
                } else {
                    Write-Host "`e[96mVirtual environment not exists.`e[0m"
                }
                break
            }

            # *Delete all cache folders
            clean {
                $dirs = Get-ChildItem -Directory -Exclude '.venv'
                foreach ($d in $dirs) {
                    if ($d.Name -match '_cache$|__pycache__') {
                        Remove-Item $d -Recurse -Force
                    } else {
                        @('*_cache', '__pycache__') | ForEach-Object {
                            [IO.Directory]::GetDirectories($d.FullName, $_, 1) | `
                                Remove-Item -Recurse -Force
                        }
                    }
                }
                break
            }

            # *Purge pip cache.
            purge {
                pip cache purge
                break
            }

            # *Generate key pairs for SSH authentication in remote repository.
            sshkey {
                if ($IsLinux) {
                    if (!(Test-Path '~/.ssh/id_rsa.pub')) {
                        # create new authentication key pairs for SSH if not exist
                        sh -c "ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''"
                    }
                    Write-Host "`e[95mAdd below key to the repository's SSH keys:`e[0m"
                    Get-Content '~/.ssh/id_rsa.pub'
                } elseif ($IsWindows) {
                    Write-Host "`e[96mYou don't need to crete key for SSH, use HTTPS.`e[0m`n"
                }
                break
            }

            # *Trust SSL connection to pypi.org.
            ssltrust {
                if ($IsWindows) {
                    $pipLocation = "$env:APPDATA\pip\pip.ini"
                } elseif ($IsLinux -or $IsMacOS) {
                    $pipLocation = "$env:HOME/.config/pip/pip.conf"
                }
                $pipConfDir = [IO.Path]::GetDirectoryName($pipLocation)
                if (!(Test-Path $pipConfDir)) { New-Item $pipConfDir -ItemType Directory | Out-Null }
                Set-Content $pipLocation -Value "[global]`ntrusted-host = pypi.org`n`tpypi.python.org`n`tfiles.pythonhosted.org"
                break
            }

            # *Set project environment variables.
            setenv {
                # set environment targed depending on host system
                foreach ($prop in $envVars.PSObject.Properties) {
                    if ($IsWindows) {
                        [Environment]::SetEnvironmentVariable($prop.Name, $prop.Value, 'User')
                        # refresh environment
                        try {
                            RefreshEnv.cmd
                        } catch {
                            taskkill.exe /F /IM explorer.exe; Start-Process explorer.exe
                        }
                    } else {
                        if (!([Environment]::GetEnvironmentVariable($prop.Name))) {
                            "export $($prop.Name)=""$($prop.Value)""" >> ~/.profile
                        }
                    }
                }
                break
            }

            # *Get project environment variables.
            getenv {
                foreach ($prop in $envVars.PSObject.Properties) {
                    [PSCustomObject]@{
                        Variable = $prop.Name
                        Value    = [Environment]::GetEnvironmentVariable($prop.Value)
                    }
                }
                break
            }

            # *List installed modules.
            list {
                python3 -m pip list --format=json | ConvertFrom-Json | Tee-Object -Variable modules | Format-Table
                $pipPath = (python3 -m pip -V) -replace '^.*from |pip \(.*$'
                Write-Host "`e[96m$(python3 -V) `e[0m|`e[96m $($modules.Count) modules installed in `e[1;34m$pipPath`e[0m"
                break
            }

            # *Setup python virtual environment.
            venv {
                # create virtual environment
                if ($null -eq $env:VIRTUAL_ENV) {
                    Write-Host "`e[96mSet up Python environment.`e[0m"
                    if (-not $venvCreated) {
                        python3 -m venv $VENV_DIR
                    }
                    # activate virtual environment
                    & $activateScript
                } else {
                    Write-Host "`e[96mVirtual environment already set.`e[0m"
                }
                # add files to the project
                if (-not (Test-Path '.gitignore')) {
                    Write-Host "`e[95madd Python .gitignore`e[0m"
                    [Net.WebClient]::new().DownloadFile($GITIGNORE, '.gitignore')
                }
                if (-not (Test-Path $req.name)) {
                    Write-Host "`e[95madd `e[1;3mrequirements.txt`e[22;23m with dev modules`e[0m"
                    New-Item $req.name -Value $req.value | Out-Null
                }
                if (-not (Test-Path $initScript)) {
                    Write-Host "`e[95mcreate `e[1;3minit.ps1`e[22;23m for virtual environment activation`e[0m"
                    $initContent = (
                        "#!/usr/bin/pwsh -nop`n#Requires -Version 7.0`n" +
                        "`$activateScript = [IO.Path]::Combine('$VENV_DIR', (`$IsWindows ? 'Scripts' : 'bin'), 'Activate.ps1')`n" +
                        "if (Test-Path `$activateScript) {`n`t& `$activateScript`n}`n"
                    )
                    New-Item -Path $initScript -Value $initContent -Force | Out-Null
                    if ($IsLinux) {
                        chmod +x $initScript
                    }
                }
            }

            # *Update pip, wheel and setuptools.
            { $_ -in @('install', 'venv', 'update') } {
                Write-Host "`e[95mupdate pip, wheel and setuptools`e[0m"
                python3 -m pip install -U pip wheel setuptools
            }

            # *Install requirements.
            { $_ -in @('install', 'venv') } {
                if (Test-Path $req.name) {
                    # get modules from requirements files
                    $modules = $req_files | ForEach-Object { Get-Content $_ }
                }
                if ($modules) {
                    Write-Host "`e[95install requirements`e[0m"
                    $reqs_temp = 'reqs_temp.txt'
                    Set-Content -Path $reqs_temp -Value $modules
                    python3 -m pip install -U -r $reqs_temp
                    Remove-Item $reqs_temp
                }
                # add project path in virtual environment
                if ($env:VIRTUAL_ENV -and 'pypath-magic' -in $modules) {
                    pypath add ([IO.Path]::Combine($PWD, $AppPath)) 2>$null
                    pypath add $PWD 2>$null
                }
                break
            }

            # *Update all modules.
            update {
                $modules = (python3 -m pip list --format=json | ConvertFrom-Json).name
                if ($modules) {
                    Write-Host "`e[95mupdate all modules`e[0m"
                    $reqs_temp = 'reqs_temp.txt'
                    Set-Content -Path $reqs_temp -Value $modules
                    python3 -m pip install -U -r $reqs_temp
                    Remove-Item $reqs_temp
                }
                break
            }
        }
    }
}

Set-Alias -Name ips -Value Invoke-PySetup
