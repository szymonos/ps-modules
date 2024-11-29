$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/alias.ps1
. $PSScriptRoot/Functions/completers.ps1
. $PSScriptRoot/Functions/helper.ps1
. $PSScriptRoot/Functions/internal.ps1

$exportModuleMemberParams = @{
    Function = @(
        # :completer functions
        'ArgGitGetBranches'
        'ArgGitGetStashList'
        # :helper function
        # branch delete
        'gbd'
        'gbd!'
        'gbdo'
        'gbdo!'
        'gbdl'
        'gbdl!'
        'gbdm'
        'gbdm!'
        'gpushd'
        # grep
        'ggrep'
        'ggrepa'
        'ggrepc'
        'ggrepca'
        # log
        'gglo'
        'ggloa'
        # log colored
        'ggloc'
        'ggloca'
        'gglot'
        # merge/rebase
        'gmg'
        'gmgo'
        'grb'
        'grbo'
        'gmb'
        'grmb'
        # grun
        'grunrepocmd'
        'grunrefresh'
        'gruncfl'
        # stash
        'gstaap'
        'gstad'
        'gstas'
        'gstast'
        # switch
        'gsw'
        'gsw!'
        # :alias functions
        'ga'
        'gaa'
        'gapa'
        'gau'
        'gbl'
        'gb'
        'gba'
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
        'gac'
        'gacp'
        'gca!'
        'gac!'
        'gcam'
        'gcamp'
        'gacm'
        'gacmp'
        'gcan!'
        'gcanp!'
        'gacn!'
        'gacnp!'
        'gcns!'
        'gcans!'
        'gacns!'
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
        'glont'
        'glop'
        'glopa'
        'glos'
        'glosa'
        'glosp'
        'glospa'
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
        'gpushdr'
        'gpushoat'
        'gpushsup'
        'gpusht'
        'gpusht!'
        'gpushv'
        'grba'
        'grbc'
        'grbi'
        'grbs'
        'gr'
        'grh'
        'grho'
        'grs'
        'grl'
        'grmc'
        'grm!'
        'grmrc'
        'grmr!'
        'grp'
        'grr'
        'grrsrc'
        'grrstg'
        'grt'
        'grta'
        'grtrm'
        'grtrn'
        'grtsu'
        'grtup'
        'grtupp'
        'grtv'
        'gswc'
        'gswd'
        'gswo'
        'gsmi'
        'gsmu'
        'gsps'
        'gsta'
        'gstaa'
        'gstac'
        'gstal'
        'gstap'
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
