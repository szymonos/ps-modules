#
# Module manifest for module 'aliases-kubectl'
#
# Generated by: szymono
#
# Generated on: 2023-04-04
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'aliases-kubectl.psm1'

# Version number of this module.
ModuleVersion = '0.4.1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '5130f101-34ad-4995-9502-0f8322b1ad6f'

# Author of this module
Author = 'Szymon Osiecki'

# Company or vendor of this module
# CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) Szymon Osiecki. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This module contains kubectl alias functions.'

# Minimum version of the PowerShell engine required by this module
CompatiblePSEditions = @('Core')
PowerShellVersion = '7.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    # helper
    'Get-KubectlVersion'
    'Get-KubectlClientVersion'
    'Get-KubectlServerVersion'
    'Set-KubectlLocal'
    'Get-KubectlContext'
    'Set-KubectlContext'
    'Remove-KubectlContext'
    'Get-KubectlSecretDecodedData'
    'Set-KubectlContextCurrentNamespace'
    # alias
    'ktop'
    'ktopcntr'
    'kinf'
    'kav'
    'kcv'
    'ksys'
    'ka'
    'ksysa'
    'kak'
    'kk'
    'krmk'
    'kex'
    'kexsh'
    'kexbash'
    'kexpwsh'
    'kexpy'
    'kexipy'
    'kre'
    'kre!'
    'kref'
    'kref!'
    'ksysex'
    'klo'
    'ksyslo'
    'klop'
    'ksyslop'
    'kp'
    'kpf'
    'kg'
    'ksysg'
    'kd'
    'ksysd'
    'krm'
    'ksysrm'
    'krun'
    'ksysrun'
    'kgpo'
    'ksysgpo'
    'kdpo'
    'ksysdpo'
    'krmpo'
    'ksysrmpo'
    'kgdep'
    'ksysgdep'
    'kddep'
    'ksysddep'
    'krmdep'
    'ksysrmdep'
    'kgsvc'
    'ksysgsvc'
    'kdsvc'
    'ksysdsvc'
    'krmsvc'
    'ksysrmsvc'
    'kging'
    'ksysging'
    'kding'
    'ksysding'
    'krming'
    'ksysrming'
    'kgcm'
    'ksysgcm'
    'kdcm'
    'ksysdcm'
    'krmcm'
    'ksysrmcm'
    'kgsec'
    'ksysgsec'
    'kdsec'
    'ksysdsec'
    'krmsec'
    'ksysrmsec'
    'kgno'
    'kdno'
    'kgns'
    'kdns'
    'krmns'
    'kgoyaml'
    'ksysgoyaml'
    'kgpooyaml'
    'ksysgpooyaml'
    'kgdepoyaml'
    'ksysgdepoyaml'
    'kgsvcoyaml'
    'ksysgsvcoyaml'
    'kgingoyaml'
    'ksysgingoyaml'
    'kgcmoyaml'
    'ksysgcmoyaml'
    'kgsecoyaml'
    'ksysgsecoyaml'
    'kgnooyaml'
    'kgnsoyaml'
    'kgowide'
    'ksysgowide'
    'kgpoowide'
    'ksysgpoowide'
    'kgdepowide'
    'ksysgdepowide'
    'kgsvcowide'
    'ksysgsvcowide'
    'kgingowide'
    'ksysgingowide'
    'kgcmowide'
    'ksysgcmowide'
    'kgsecowide'
    'ksysgsecowide'
    'kgnoowide'
    'kgnsowide'
    'kgojson'
    'ksysgojson'
    'kgpoojson'
    'ksysgpoojson'
    'kgdepojson'
    'ksysgdepojson'
    'kgsvcojson'
    'ksysgsvcojson'
    'kgingojson'
    'ksysgingojson'
    'kgcmojson'
    'ksysgcmojson'
    'kgsecojson'
    'ksysgsecojson'
    'kgnoojson'
    'kgnsojson'
    'kgall'
    'kdall'
    'kgpoall'
    'kdpoall'
    'kgdepall'
    'kddepall'
    'kgsvcall'
    'kdsvcall'
    'kgingall'
    'kdingall'
    'kgcmall'
    'kdcmall'
    'kgsecall'
    'kdsecall'
    'kgnsall'
    'kdnsall'
    'kgsl'
    'ksysgsl'
    'kgposl'
    'ksysgposl'
    'kgdepsl'
    'ksysgdepsl'
    'krmall'
    'ksysrmall'
    'krmpoall'
    'ksysrmpoall'
    'krmdepall'
    'ksysrmdepall'
    'krmsvcall'
    'ksysrmsvcall'
    'krmingall'
    'ksysrmingall'
    'krmcmall'
    'ksysrmcmall'
    'krmsecall'
    'ksysrmsecall'
    'krmnsall'
    'kgw'
    'ksysgw'
    'kgpow'
    'ksysgpow'
    'kgdepw'
    'ksysgdepw'
    'kgsvcw'
    'ksysgsvcw'
    'kgingw'
    'ksysgingw'
    'kgcmw'
    'ksysgcmw'
    'kgsecw'
    'ksysgsecw'
    'kgnow'
    'kgnsw'
    'kgoyamlall'
    'kgpooyamlall'
    'kgdepoyamlall'
    'kgsvcoyamlall'
    'kgingoyamlall'
    'kgcmoyamlall'
    'kgsecoyamlall'
    'kgnsoyamlall'
    'kgalloyaml'
    'kgpoalloyaml'
    'kgdepalloyaml'
    'kgsvcalloyaml'
    'kgingalloyaml'
    'kgcmalloyaml'
    'kgsecalloyaml'
    'kgnsalloyaml'
    'kgwoyaml'
    'ksysgwoyaml'
    'kgpowoyaml'
    'ksysgpowoyaml'
    'kgdepwoyaml'
    'ksysgdepwoyaml'
    'kgsvcwoyaml'
    'ksysgsvcwoyaml'
    'kgingwoyaml'
    'ksysgingwoyaml'
    'kgcmwoyaml'
    'ksysgcmwoyaml'
    'kgsecwoyaml'
    'ksysgsecwoyaml'
    'kgnowoyaml'
    'kgnswoyaml'
    'kgowideall'
    'kgpoowideall'
    'kgdepowideall'
    'kgsvcowideall'
    'kgingowideall'
    'kgcmowideall'
    'kgsecowideall'
    'kgnsowideall'
    'kgallowide'
    'kgpoallowide'
    'kgdepallowide'
    'kgsvcallowide'
    'kgingallowide'
    'kgcmallowide'
    'kgsecallowide'
    'kgnsallowide'
    'kgowidesl'
    'ksysgowidesl'
    'kgpoowidesl'
    'ksysgpoowidesl'
    'kgdepowidesl'
    'ksysgdepowidesl'
    'kgslowide'
    'ksysgslowide'
    'kgposlowide'
    'ksysgposlowide'
    'kgdepslowide'
    'ksysgdepslowide'
    'kgwowide'
    'ksysgwowide'
    'kgpowowide'
    'ksysgpowowide'
    'kgdepwowide'
    'ksysgdepwowide'
    'kgsvcwowide'
    'ksysgsvcwowide'
    'kgingwowide'
    'ksysgingwowide'
    'kgcmwowide'
    'ksysgcmwowide'
    'kgsecwowide'
    'ksysgsecwowide'
    'kgnowowide'
    'kgnswowide'
    'kgojsonall'
    'kgpoojsonall'
    'kgdepojsonall'
    'kgsvcojsonall'
    'kgingojsonall'
    'kgcmojsonall'
    'kgsecojsonall'
    'kgnsojsonall'
    'kgallojson'
    'kgpoallojson'
    'kgdepallojson'
    'kgsvcallojson'
    'kgingallojson'
    'kgcmallojson'
    'kgsecallojson'
    'kgnsallojson'
    'kgwojson'
    'ksysgwojson'
    'kgpowojson'
    'ksysgpowojson'
    'kgdepwojson'
    'ksysgdepwojson'
    'kgsvcwojson'
    'ksysgsvcwojson'
    'kgingwojson'
    'ksysgingwojson'
    'kgcmwojson'
    'ksysgcmwojson'
    'kgsecwojson'
    'ksysgsecwojson'
    'kgnowojson'
    'kgnswojson'
    'kgallsl'
    'kgpoallsl'
    'kgdepallsl'
    'kgslall'
    'kgposlall'
    'kgdepslall'
    'kgallw'
    'kgpoallw'
    'kgdepallw'
    'kgsvcallw'
    'kgingallw'
    'kgcmallw'
    'kgsecallw'
    'kgnsallw'
    'kgwall'
    'kgpowall'
    'kgdepwall'
    'kgsvcwall'
    'kgingwall'
    'kgcmwall'
    'kgsecwall'
    'kgnswall'
    'kgslw'
    'ksysgslw'
    'kgposlw'
    'ksysgposlw'
    'kgdepslw'
    'ksysgdepslw'
    'kgwsl'
    'ksysgwsl'
    'kgpowsl'
    'ksysgpowsl'
    'kgdepwsl'
    'ksysgdepwsl'
    'kgallwoyaml'
    'kgpoallwoyaml'
    'kgdepallwoyaml'
    'kgsvcallwoyaml'
    'kgingallwoyaml'
    'kgcmallwoyaml'
    'kgsecallwoyaml'
    'kgnsallwoyaml'
    'kgwoyamlall'
    'kgpowoyamlall'
    'kgdepwoyamlall'
    'kgsvcwoyamlall'
    'kgingwoyamlall'
    'kgcmwoyamlall'
    'kgsecwoyamlall'
    'kgnswoyamlall'
    'kgwalloyaml'
    'kgpowalloyaml'
    'kgdepwalloyaml'
    'kgsvcwalloyaml'
    'kgingwalloyaml'
    'kgcmwalloyaml'
    'kgsecwalloyaml'
    'kgnswalloyaml'
    'kgowideallsl'
    'kgpoowideallsl'
    'kgdepowideallsl'
    'kgowideslall'
    'kgpoowideslall'
    'kgdepowideslall'
    'kgallowidesl'
    'kgpoallowidesl'
    'kgdepallowidesl'
    'kgallslowide'
    'kgpoallslowide'
    'kgdepallslowide'
    'kgslowideall'
    'kgposlowideall'
    'kgdepslowideall'
    'kgslallowide'
    'kgposlallowide'
    'kgdepslallowide'
    'kgallwowide'
    'kgpoallwowide'
    'kgdepallwowide'
    'kgsvcallwowide'
    'kgingallwowide'
    'kgcmallwowide'
    'kgsecallwowide'
    'kgnsallwowide'
    'kgwowideall'
    'kgpowowideall'
    'kgdepwowideall'
    'kgsvcwowideall'
    'kgingwowideall'
    'kgcmwowideall'
    'kgsecwowideall'
    'kgnswowideall'
    'kgwallowide'
    'kgpowallowide'
    'kgdepwallowide'
    'kgsvcwallowide'
    'kgingwallowide'
    'kgcmwallowide'
    'kgsecwallowide'
    'kgnswallowide'
    'kgslwowide'
    'ksysgslwowide'
    'kgposlwowide'
    'ksysgposlwowide'
    'kgdepslwowide'
    'ksysgdepslwowide'
    'kgwowidesl'
    'ksysgwowidesl'
    'kgpowowidesl'
    'ksysgpowowidesl'
    'kgdepwowidesl'
    'ksysgdepwowidesl'
    'kgwslowide'
    'ksysgwslowide'
    'kgpowslowide'
    'ksysgpowslowide'
    'kgdepwslowide'
    'ksysgdepwslowide'
    'kgallwojson'
    'kgpoallwojson'
    'kgdepallwojson'
    'kgsvcallwojson'
    'kgingallwojson'
    'kgcmallwojson'
    'kgsecallwojson'
    'kgnsallwojson'
    'kgwojsonall'
    'kgpowojsonall'
    'kgdepwojsonall'
    'kgsvcwojsonall'
    'kgingwojsonall'
    'kgcmwojsonall'
    'kgsecwojsonall'
    'kgnswojsonall'
    'kgwallojson'
    'kgpowallojson'
    'kgdepwallojson'
    'kgsvcwallojson'
    'kgingwallojson'
    'kgcmwallojson'
    'kgsecwallojson'
    'kgnswallojson'
    'kgallslw'
    'kgpoallslw'
    'kgdepallslw'
    'kgallwsl'
    'kgpoallwsl'
    'kgdepallwsl'
    'kgslallw'
    'kgposlallw'
    'kgdepslallw'
    'kgslwall'
    'kgposlwall'
    'kgdepslwall'
    'kgwallsl'
    'kgpowallsl'
    'kgdepwallsl'
    'kgwslall'
    'kgpowslall'
    'kgdepwslall'
    'kgallslwowide'
    'kgpoallslwowide'
    'kgdepallslwowide'
    'kgallwowidesl'
    'kgpoallwowidesl'
    'kgdepallwowidesl'
    'kgallwslowide'
    'kgpoallwslowide'
    'kgdepallwslowide'
    'kgslallwowide'
    'kgposlallwowide'
    'kgdepslallwowide'
    'kgslwowideall'
    'kgposlwowideall'
    'kgdepslwowideall'
    'kgslwallowide'
    'kgposlwallowide'
    'kgdepslwallowide'
    'kgwowideallsl'
    'kgpowowideallsl'
    'kgdepwowideallsl'
    'kgwowideslall'
    'kgpowowideslall'
    'kgdepwowideslall'
    'kgwallowidesl'
    'kgpowallowidesl'
    'kgdepwallowidesl'
    'kgwallslowide'
    'kgpowallslowide'
    'kgdepwallslowide'
    'kgwslowideall'
    'kgpowslowideall'
    'kgdepwslowideall'
    'kgwslallowide'
    'kgpowslallowide'
    'kgdepwslallowide'
    'kgf'
    'kdf'
    'krmf'
    'kgoyamlf'
    'kgowidef'
    'kgojsonf'
    'kgslf'
    'kgwf'
    'kgwoyamlf'
    'kgowideslf'
    'kgslowidef'
    'kgwowidef'
    'kgwojsonf'
    'kgslwf'
    'kgwslf'
    'kgslwowidef'
    'kgwowideslf'
    'kgwslowidef'
    'kgl'
    'ksysgl'
    'kdl'
    'ksysdl'
    'krml'
    'ksysrml'
    'kgpol'
    'ksysgpol'
    'kdpol'
    'ksysdpol'
    'krmpol'
    'ksysrmpol'
    'kgdepl'
    'ksysgdepl'
    'kddepl'
    'ksysddepl'
    'krmdepl'
    'ksysrmdepl'
    'kgsvcl'
    'ksysgsvcl'
    'kdsvcl'
    'ksysdsvcl'
    'krmsvcl'
    'ksysrmsvcl'
    'kgingl'
    'ksysgingl'
    'kdingl'
    'ksysdingl'
    'krmingl'
    'ksysrmingl'
    'kgcml'
    'ksysgcml'
    'kdcml'
    'ksysdcml'
    'krmcml'
    'ksysrmcml'
    'kgsecl'
    'ksysgsecl'
    'kdsecl'
    'ksysdsecl'
    'krmsecl'
    'ksysrmsecl'
    'kgnol'
    'kdnol'
    'kgnsl'
    'kdnsl'
    'krmnsl'
    'kgoyamll'
    'ksysgoyamll'
    'kgpooyamll'
    'ksysgpooyamll'
    'kgdepoyamll'
    'ksysgdepoyamll'
    'kgsvcoyamll'
    'ksysgsvcoyamll'
    'kgingoyamll'
    'ksysgingoyamll'
    'kgcmoyamll'
    'ksysgcmoyamll'
    'kgsecoyamll'
    'ksysgsecoyamll'
    'kgnooyamll'
    'kgnsoyamll'
    'kgowidel'
    'ksysgowidel'
    'kgpoowidel'
    'ksysgpoowidel'
    'kgdepowidel'
    'ksysgdepowidel'
    'kgsvcowidel'
    'ksysgsvcowidel'
    'kgingowidel'
    'ksysgingowidel'
    'kgcmowidel'
    'ksysgcmowidel'
    'kgsecowidel'
    'ksysgsecowidel'
    'kgnoowidel'
    'kgnsowidel'
    'kgojsonl'
    'ksysgojsonl'
    'kgpoojsonl'
    'ksysgpoojsonl'
    'kgdepojsonl'
    'ksysgdepojsonl'
    'kgsvcojsonl'
    'ksysgsvcojsonl'
    'kgingojsonl'
    'ksysgingojsonl'
    'kgcmojsonl'
    'ksysgcmojsonl'
    'kgsecojsonl'
    'ksysgsecojsonl'
    'kgnoojsonl'
    'kgnsojsonl'
    'kgsll'
    'ksysgsll'
    'kgposll'
    'ksysgposll'
    'kgdepsll'
    'ksysgdepsll'
    'kgwl'
    'ksysgwl'
    'kgpowl'
    'ksysgpowl'
    'kgdepwl'
    'ksysgdepwl'
    'kgsvcwl'
    'ksysgsvcwl'
    'kgingwl'
    'ksysgingwl'
    'kgcmwl'
    'ksysgcmwl'
    'kgsecwl'
    'ksysgsecwl'
    'kgnowl'
    'kgnswl'
    'kgwoyamll'
    'ksysgwoyamll'
    'kgpowoyamll'
    'ksysgpowoyamll'
    'kgdepwoyamll'
    'ksysgdepwoyamll'
    'kgsvcwoyamll'
    'ksysgsvcwoyamll'
    'kgingwoyamll'
    'ksysgingwoyamll'
    'kgcmwoyamll'
    'ksysgcmwoyamll'
    'kgsecwoyamll'
    'ksysgsecwoyamll'
    'kgnowoyamll'
    'kgnswoyamll'
    'kgowidesll'
    'ksysgowidesll'
    'kgpoowidesll'
    'ksysgpoowidesll'
    'kgdepowidesll'
    'ksysgdepowidesll'
    'kgslowidel'
    'ksysgslowidel'
    'kgposlowidel'
    'ksysgposlowidel'
    'kgdepslowidel'
    'ksysgdepslowidel'
    'kgwowidel'
    'ksysgwowidel'
    'kgpowowidel'
    'ksysgpowowidel'
    'kgdepwowidel'
    'ksysgdepwowidel'
    'kgsvcwowidel'
    'ksysgsvcwowidel'
    'kgingwowidel'
    'ksysgingwowidel'
    'kgcmwowidel'
    'ksysgcmwowidel'
    'kgsecwowidel'
    'ksysgsecwowidel'
    'kgnowowidel'
    'kgnswowidel'
    'kgwojsonl'
    'ksysgwojsonl'
    'kgpowojsonl'
    'ksysgpowojsonl'
    'kgdepwojsonl'
    'ksysgdepwojsonl'
    'kgsvcwojsonl'
    'ksysgsvcwojsonl'
    'kgingwojsonl'
    'ksysgingwojsonl'
    'kgcmwojsonl'
    'ksysgcmwojsonl'
    'kgsecwojsonl'
    'ksysgsecwojsonl'
    'kgnowojsonl'
    'kgnswojsonl'
    'kgslwl'
    'ksysgslwl'
    'kgposlwl'
    'ksysgposlwl'
    'kgdepslwl'
    'ksysgdepslwl'
    'kgwsll'
    'ksysgwsll'
    'kgpowsll'
    'ksysgpowsll'
    'kgdepwsll'
    'ksysgdepwsll'
    'kgslwowidel'
    'ksysgslwowidel'
    'kgposlwowidel'
    'ksysgposlwowidel'
    'kgdepslwowidel'
    'ksysgdepslwowidel'
    'kgwowidesll'
    'ksysgwowidesll'
    'kgpowowidesll'
    'ksysgpowowidesll'
    'kgdepwowidesll'
    'ksysgdepwowidesll'
    'kgwslowidel'
    'ksysgwslowidel'
    'kgpowslowidel'
    'ksysgpowslowidel'
    'kgdepwslowidel'
    'ksysgdepwslowidel'
    'kexn'
    'klon'
    'kpfn'
    'kgn'
    'kdn'
    'krmn'
    'kgpon'
    'kdpon'
    'krmpon'
    'kgdepn'
    'kddepn'
    'krmdepn'
    'kgsvcn'
    'kdsvcn'
    'krmsvcn'
    'kgingn'
    'kdingn'
    'krmingn'
    'kgcmn'
    'kdcmn'
    'krmcmn'
    'kgsecn'
    'kdsecn'
    'krmsecn'
    'kgoyamln'
    'kgpooyamln'
    'kgdepoyamln'
    'kgsvcoyamln'
    'kgingoyamln'
    'kgcmoyamln'
    'kgsecoyamln'
    'kgowiden'
    'kgpoowiden'
    'kgdepowiden'
    'kgsvcowiden'
    'kgingowiden'
    'kgcmowiden'
    'kgsecowiden'
    'kgojsonn'
    'kgpoojsonn'
    'kgdepojsonn'
    'kgsvcojsonn'
    'kgingojsonn'
    'kgcmojsonn'
    'kgsecojsonn'
    'kgsln'
    'kgposln'
    'kgdepsln'
    'kgwn'
    'kgpown'
    'kgdepwn'
    'kgsvcwn'
    'kgingwn'
    'kgcmwn'
    'kgsecwn'
    'kgwoyamln'
    'kgpowoyamln'
    'kgdepwoyamln'
    'kgsvcwoyamln'
    'kgingwoyamln'
    'kgcmwoyamln'
    'kgsecwoyamln'
    'kgowidesln'
    'kgpoowidesln'
    'kgdepowidesln'
    'kgslowiden'
    'kgposlowiden'
    'kgdepslowiden'
    'kgwowiden'
    'kgpowowiden'
    'kgdepwowiden'
    'kgsvcwowiden'
    'kgingwowiden'
    'kgcmwowiden'
    'kgsecwowiden'
    'kgwojsonn'
    'kgpowojsonn'
    'kgdepwojsonn'
    'kgsvcwojsonn'
    'kgingwojsonn'
    'kgcmwojsonn'
    'kgsecwojsonn'
    'kgslwn'
    'kgposlwn'
    'kgdepslwn'
    'kgwsln'
    'kgpowsln'
    'kgdepwsln'
    'kgslwowiden'
    'kgposlwowiden'
    'kgdepslwowiden'
    'kgwowidesln'
    'kgpowowidesln'
    'kgdepwowidesln'
    'kgwslowiden'
    'kgpowslowiden'
    'kgdepwslowiden'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @(
    'k'
    'kv'
    'kvc'
    'kvs'
    'kcgctx'
    'kcuctx'
    'kcrmctx'
    'kgsecd'
    'kcsctxcns'
)

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/szymonos/devops-scripts/modules/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/szymonos/devops-scripts/modules/aliases-kubectl'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        Prerelease = 'beta'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
