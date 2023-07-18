# ps-modules

Repository with PowerShell modules I've developed over time.

## Managing modules

You can manage modules in the repository with [module_manage.ps1](./module_manage.ps1) script.  
It allows to install the module, delete module, or scaffold new module manifest in the repository.  
Script automatically detects the `CurrentUser`/`AllUsers` scope, depending if it runs elevated.

``` PowerShell
# install module
./module_manage.ps1 -Module 'do-test'
# clean up previous versions during installation
./module_manage.ps1 -Module 'do-test' -CleanUp
# remove requirements from the manifest file to speed up module loading
./module_manage.ps1 -Module 'do-test' -RemoveRequirements

# delete module
./module_manage.ps1 -Module 'do-test' -Delete

# scaffold module manifest
./module_manage.ps1 -Module 'do-test' -Create
```

## Modules

- [`aliases-git`](docs/aliases_git.md)

  Module with git functions and aliases.

  ``` PowerShell
  ./module_manage.ps1 'aliases-git' -CleanUp
  ```

- [`aliases-kubectl`](docs/aliases_kubectl.md)

  Module with kubectl functions and aliases.

  ``` PowerShell
  ./module_manage.ps1 'aliases-kubectl' -CleanUp
  ```

- [`do-az`](docs/do_az.md)

  Module intended to streamline work with Microsoft Azure Cloud.  
  Required modules to be installed beforehand: `do-common`, `Az.Accounts`, `Az.ResourceGraph`

  ``` PowerShell
  ./module_manage.ps1 'do-az' -CleanUp -RemoveRequirements
  ```

- [`do-common`](docs/do_common.md)

  Common module, not depending on other modules, working on all systems.  
  On Linux, it is recommended to install the module in the `AllUsers` scope, by running the script as root.

  ``` PowerShell
  ./module_manage.ps1 'do-common' -CleanUp
  ```

- [`do-linux`](docs/do_linux.md)

  Module intended to streamline work on Linux.

  ``` PowerShell
  ./module_manage.ps1 -Module 'do-linux' -CleanUp
  ```

- [`do-win`](docs/do_win.md)

  Module intended to streamline work on Windows.

  ``` PowerShell
  ./module_manage.ps1 -Module 'do-win' -CleanUp
  ```
