# ps-szymonos

Repository for my *DevOps* PowerShell modules.

## Managing modules

You can manage modules in the repository with [module_manage.ps1](./module_manage.ps1) script.  
It allows to install the module, delete module, or scaffold new module manifest in the repository.  
Script automatically detects the `CurrentUser`/`AllUsers` scope depending if it runs elevated.

``` PowerShell
<# install module #>
./module_manage.ps1 -Module 'do-test'
# clean up previous versions during installation
./module_manage.ps1 -Module 'do-test' -CleanUp
# remove requirements from the manifest file to speed up module loading
./module_manage.ps1 -Module 'do-test' -RemoveRequirements

<# delete module #>
./module_manage.ps1 -Module 'do-test' -Delete

<# scaffold module manifest #>
./module_manage.ps1 -Module 'do-test' -Create
```

## Modules

### **do-common**

Common module, not depending on other modules, working on all systems.  
It is recommended to install the module in `AllUsers` scope.

``` PowerShell
./module_manage.ps1 'do-common' -CleanUp
```

### **do-az**

Module intended to streamline work with Microsoft Azure Cloud.

``` PowerShell
./module_manage.ps1 'do-az' -CleanUp -RemoveRequirements
```

### **do-linux**

Module intended to streamline work on Linux.

``` PowerShell
./module_manage.ps1 -Module 'do-linux' -CleanUp
```

### **do-win**

Module intended to streamline work on Windows.

``` PowerShell
./module_manage.ps1 -Module 'do-win' -CleanUp
```
