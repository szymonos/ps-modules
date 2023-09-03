. $PSScriptRoot/Functions/alias.ps1
. $PSScriptRoot/Functions/helper.ps1
. $PSScriptRoot/Functions/internal.ps1

$exportModuleMemberParams = @{
    Function = @(
        # helper
        'gglo'
        'ggloa'
        'ggloc'
        'ggloca'
        'ggrep'
        'ggrepa'
        'ggrepc'
        'ggrepca'
        # alias
        'ga'
        'gaa'
        'gapa'
        'gau'
        'gbl'
        'gb'
        'gba'
        'gbd'
        'gbd!'
        'gbdl'
        'gbdla'
        'gbnm'
        'gbr'
        'gbsu'
        'gbs'
        'gbsb'
        'gbsg'
        'gbsr'
        'gbss'
        'gcv'
        'gc!'
        'gca'
        'gcap'
        'gaca'
        'gacap'
        'gca!'
        'gaca!'
        'gcam'
        'gcamp'
        'gacam'
        'gacamp'
        'gcan!'
        'gcanp!'
        'gacan!'
        'gacanp!'
        'gcans!'
        'gacans!'
        'gcmsg'
        'gcmsgp'
        'gcempty'
        'gcn!'
        'gcnp!'
        'gcsm'
        'gcd'
        'gcf'
        'gcfg'
        'gcfge'
        'gcfgl'
        'gcfl'
        'gcfle'
        'gcfll'
        'gcl'
        'gclean'
        'gclean!'
        'gpristine'
        'gco'
        'gcount'
        'gcp'
        'gcpa'
        'gcpc'
        'gcps'
        'gd'
        'gdca'
        'gdt'
        'gdw'
        'gdct'
        'gf'
        'gfa'
        'gfa!'
        'gfo'
        'gg'
        'ggc'
        'ggca'
        'gge'
        'ggp'
        'ghh'
        'gignore'
        'gignored'
        'glo'
        'gloa'
        'glog'
        'gloga'
        'glol'
        'glola'
        'glon'
        'glona'
        'glong'
        'glonga'
        'glop'
        'glopa'
        'glos'
        'glosa'
        'glosp'
        'glospa'
        'gmb'
        'gmg'
        'gmgo'
        'gmt'
        'gmtvim'
        'gpl'
        'gpl!'
        'gpull'
        'gpullr'
        'gpullra'
        'gpullrav'
        'gpullrv'
        'gpush'
        'gpush!'
        'gpushd'
        'gpushdr'
        'gpushoat'
        'gpushsup'
        'gpushv'
        'grb'
        'grba'
        'grbc'
        'grbi'
        'grbo'
        'grbs'
        'gr'
        'grh'
        'grho'
        'grmb'
        'grs'
        'grmc'
        'grm!'
        'grmrc'
        'grmr!'
        'grr'
        'grrs'
        'grt'
        'grta'
        'grtrm'
        'grtrn'
        'grtsu'
        'grtup'
        'grtupp'
        'grtv'
        'gsw'
        'gsw!'
        'gswc'
        'gswd'
        'gswo'
        'gsmi'
        'gsmu'
        'gsps'
        'gstaa'
        'gstac'
        'gstad'
        'gstal'
        'gstap'
        'gstas'
        'gstast'
        'gst'
        'gstb'
        'gsts'
        'gsvnd'
        'gsvnr'
        'gt'
        'gts'
        'gtr'
        'gunignore'
        'gwch'
    )
    Variable = @()
    Alias    = @()
}

Export-ModuleMember @exportModuleMemberParams
