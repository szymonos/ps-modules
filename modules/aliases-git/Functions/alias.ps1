function ga { Invoke-WriteExecCmd -Command 'git add' -Arguments $args }
function gaa { Invoke-WriteExecCmd -Command 'git add --all' -Arguments $args }
function gapa { Invoke-WriteExecCmd -Command 'git add --patch' -Arguments $args }
function gau { Invoke-WriteExecCmd -Command 'git add --update' -Arguments $args }
function gbl { Invoke-WriteExecCmd -Command 'git blame -b -w' -Arguments $args }
function gb { Invoke-WriteExecCmd -Command 'git branch' -Arguments $args }
function gba { Invoke-WriteExecCmd -Command 'git branch --all' -Arguments $args }
function gbnm { Invoke-WriteExecCmd -Command 'git branch --no-merged' -Arguments $args }
function gbr { Invoke-WriteExecCmd -Command 'git branch --remote' -Arguments $args }
function gbsu { Invoke-WriteExecCmd -Command "git branch --set-upstream-to=origin/$(Get-GitCurrentBranch)" -Arguments $args }
function gbs { Invoke-WriteExecCmd -Command 'git bisect' -Arguments $args }
function gbsb { Invoke-WriteExecCmd -Command 'git bisect bad' -Arguments $args }
function gbsg { Invoke-WriteExecCmd -Command 'git bisect good' -Arguments $args }
function gbsr { Invoke-WriteExecCmd -Command 'git bisect reset' -Arguments $args }
function gbss { Invoke-WriteExecCmd -Command 'git bisect start' -Arguments $args }
function gcv { Invoke-WriteExecCmd -Command 'git commit --verbose' -Arguments $args }
function gc! { Invoke-WriteExecCmd -Command 'git commit --verbose --amend' -Arguments $args }
function gca { Invoke-WriteExecCmd -Command 'git commit --verbose --all' -Arguments $args }
function gcap { gca @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gac { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gcv @args }
function gacp { gac @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gca! { Invoke-WriteExecCmd -Command 'git commit --verbose --all --amend' -Arguments $args }
function gac! { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gca! @args }
function gcam { Invoke-WriteExecCmd -Command 'git commit --all -m' -Arguments $args }
function gcamp { gcam @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gacm { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gcmsg @args }
function gacmp { gacm @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gcan! { Invoke-WriteExecCmd -Command 'git commit --verbose --all --no-edit --amend' -Arguments $args }
function gcanp! { gcan! @args; Invoke-WriteExecCmd 'git push --force-with-lease' -Parameters $args }
function gcempty { Invoke-WriteExecCmd 'git commit --allow-empty -m' -Arguments $args }
function gacn! { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gcn! @args }
function gacnp! { gacn! @args; Invoke-WriteExecCmd 'git push --force-with-lease' -Parameters $args }
function gcns! { Invoke-WriteExecCmd -Command 'git commit --verbose --signoff --no-edit --amend' -Arguments $args }
function gcans! { Invoke-WriteExecCmd -Command 'git commit --verbose --all --signoff --no-edit --amend' -Arguments $args }
function gacns! { Invoke-WriteExecCmd 'git add --all' -Parameters $args; gcns! @args }
function gcmsg { Invoke-WriteExecCmd -Command 'git commit -m' -Arguments $args }
function gcmsgp { gcmsg @args; Invoke-WriteExecCmd 'git push' -Parameters $args }
function gcn! { Invoke-WriteExecCmd -Command 'git commit --verbose --no-edit --amend' -Arguments $args }
function gcnp! { gcn! @args; Invoke-WriteExecCmd 'git push --force-with-lease' -Parameters $args }
function gcsm { Invoke-WriteExecCmd -Command 'git commit --signoff -m' -Arguments $args }
function gcd { Set-Location $(git rev-parse --show-toplevel 2>$null || '.') }
function gcf { Invoke-WriteExecCmd -Command 'git config' -Arguments $args }
function gcfg { Invoke-WriteExecCmd -Command 'git config --global' -Arguments $args }
function gcfge { Invoke-WriteExecCmd -Command 'git config --global --edit' -Arguments $args }
function gcfgl { Invoke-WriteExecCmd -Command 'git config --global --list' -Arguments $args }
function gcfl { Invoke-WriteExecCmd -Command 'git config --local' -Arguments $args }
function gcfle { Invoke-WriteExecCmd -Command 'git config --local --edit' -Arguments $args }
function gcfll { Invoke-WriteExecCmd -Command 'git config --local --list' -Arguments $args }
function gcl { Invoke-WriteExecCmd -Command 'git clone --recursive' -Arguments $args }
function gclean { Invoke-WriteExecCmd -Command 'git clean --force -d' -Arguments $args }
function gclean! { Invoke-WriteExecCmd 'git reset --hard' -Parameters $args; gclean @args }
function gpristine { Invoke-WriteExecCmd 'git reset --hard' -Parameters $args; gclean -x @args }
function gco { Invoke-WriteExecCmd -Command 'git checkout' -Arguments $args }
function gcount { Invoke-WriteExecCmd -Command 'git shortlog --summary --numbered' -Arguments $args }
function gcp { Invoke-WriteExecCmd -Command 'git cherry-pick' -Arguments $args }
function gcpa { Invoke-WriteExecCmd -Command 'git cherry-pick --abort' -Arguments $args }
function gcpc { Invoke-WriteExecCmd -Command 'git cherry-pick --continue' -Arguments $args }
function gcps { Invoke-WriteExecCmd -Command 'git cherry-pick --signoff' -Arguments $args }
function gd { Invoke-WriteExecCmd -Command 'git diff' -Arguments $args }
function gdca { Invoke-WriteExecCmd -Command 'git diff --cached' -Arguments $args }
function gdt { Invoke-WriteExecCmd -Command 'git diff-tree --no-commit-id --name-only -r' -Arguments $args }
function gdw { Invoke-WriteExecCmd -Command 'git diff --word-diff' -Arguments $args }
function gdct { Invoke-WriteExecCmd -Command 'git describe --tags `git rev-list --tags --max-count=1`' -Arguments $args }
function gf { Invoke-WriteExecCmd -Command 'git fetch' -Arguments $args }
function gfa { Invoke-WriteExecCmd -Command 'git fetch --all --prune' -Arguments $args }
function gfa! { Invoke-WriteExecCmd -Command 'git fetch --all --tags --prune --prune-tags --force' -Arguments $args }
function gfo {
    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCmd -Command "git fetch $remote" -Arguments $args
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function gg { Invoke-WriteExecCmd -Command 'git grep --ignore-case' -Arguments $args }
function ggc { Invoke-WriteExecCmd -Command 'git gc' -Arguments $args }
function ggca { Invoke-WriteExecCmd -Command 'git gc --aggressive' -Arguments $args }
function gge { Invoke-WriteExecCmd -Command 'git grep --ignore-case --extended-regexp' -Arguments $args }
function ggp { Invoke-WriteExecCmd -Command 'git grep --ignore-case --perl-regexp' -Arguments $args }
function ghh { Invoke-WriteExecCmd -Command 'git help' -Arguments $args }
function gignore { Invoke-WriteExecCmd -Command 'git update-index --assume-unchanged' -Arguments $args }
function gignored { Invoke-WriteExecCmd -Command 'git ls-files -v | Select-String "^[a-z]" -CaseSensitive' -Parameters $args }
function glo { Invoke-WriteExecCmd -Command 'git log --date=rfc' -Arguments $args }
function gloa { Invoke-WriteExecCmd -Command 'git log --date=rfc --all' -Arguments $args }
function glog { Invoke-WriteExecCmd -Command 'git log --date=rfc --graph' -Arguments $args }
function gloga { Invoke-WriteExecCmd -Command 'git log --date=rfc --graph --decorate --all' -Arguments $args }
function glol { Invoke-WriteExecCmd -Command 'git log --graph --pretty="%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)" --abbrev-commit -Quiet' -Arguments @($args, '-Quiet') }
function glola { Invoke-WriteExecCmd -Command 'git log --graph --pretty="%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)" --abbrev-commit --all' -Arguments @($args, '-Quiet') }
function glon { Invoke-WriteExecCmd -Command 'git log --oneline --decorate' -Arguments $args }
function glona { Invoke-WriteExecCmd -Command 'git log --oneline --decorate --all' -Arguments $args }
function glong { Invoke-WriteExecCmd -Command 'git log --oneline --decorate --graph' -Arguments $args }
function glonga { Invoke-WriteExecCmd -Command 'git log --oneline --decorate --graph --all' -Arguments $args }
function glont { Invoke-WriteExecCmd -Command 'git log --oneline --decorate --no-walk --tags="*"' -Arguments $args }
function glop { Invoke-WriteExecCmd -Command 'git log --pretty=format:"%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)" --abbrev-commit' -Arguments @($args, '-Quiet') }
function glopa { Invoke-WriteExecCmd -Command 'git log --pretty=format:"%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)" --abbrev-commit --all' -Arguments @($args, '-Quiet') }
function glos { Invoke-WriteExecCmd -Command 'git log --date=rfc --stat' -Arguments $args }
function glosa { Invoke-WriteExecCmd -Command 'git log --date=rfc --stat --all' -Arguments $args }
function glosp { Invoke-WriteExecCmd -Command 'git log --date=rfc --stat --patch' -Arguments $args }
function glospa { Invoke-WriteExecCmd -Command 'git log --date=rfc --stat --patch --all' -Arguments $args }
function gmgo {
    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCmd -Command "git fetch $remote $(Get-GitCurrentBranch) --quiet" -Parameters $args
        Invoke-WriteExecCmd -Command "git merge $remote/$(Get-GitCurrentBranch)" -Arguments $args
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function gmt { Invoke-WriteExecCmd -Command 'git mergetool --no-prompt' -Arguments $args }
function gmtvim { Invoke-WriteExecCmd -Command 'git mergetool --no-prompt --tool=vimdiff' -Arguments $args }
function gpl {
    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCmd -Command "git pull $remote $(Get-GitCurrentBranch) --tags --prune" -Arguments $args
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function gpl! { gpl --force @args }
function gpull { Invoke-WriteExecCmd -Command 'git pull' -Arguments $args }
function gpullr { Invoke-WriteExecCmd -Command 'git pull --rebase' -Arguments $args }
function gpullra { Invoke-WriteExecCmd -Command 'git pull --rebase --autostash' -Arguments $args }
function gpullrav { Invoke-WriteExecCmd -Command 'git pull --rebase --autostash --verbose' -Arguments $args }
function gpullrv { Invoke-WriteExecCmd -Command 'git pull --rebase --verbose' -Arguments $args }
function gpush { Invoke-WriteExecCmd -Command 'git push' -Arguments $args }
function gpush! { Invoke-WriteExecCmd -Command 'git push --force-with-lease' -Arguments $args }
function gpushdr { Invoke-WriteExecCmd -Command 'git push --dry-run' -Arguments $args }
function gpushoat {
    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCmd -Command "git push $remote --all && git push $remote --tags" -Parameters $args
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function gpushsup { Invoke-WriteExecCmd -Command "git push --set-upstream origin $(Get-GitCurrentBranch)" -Arguments $args }
function gpusht { Invoke-WriteExecCmd -Command 'git push --tags' -Arguments $args }
function gpusht! { Invoke-WriteExecCmd -Command 'git push --tags --force' -Arguments $args }
function gpushv { Invoke-WriteExecCmd -Command 'git push --verbose' -Arguments $args }
function grba { Invoke-WriteExecCmd -Command 'git rebase --abort' -Arguments $args }
function grbc { Invoke-WriteExecCmd -Command 'git rebase --continue' -Arguments $args }
function grbi { Invoke-WriteExecCmd -Command 'git rebase --interactive' -Arguments $args }
function grbo {
    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCmd -Command "git fetch $remote $(Get-GitCurrentBranch) --quiet" -Parameters $args
        Invoke-WriteExecCmd -Command "git rebase $remote/$(Get-GitCurrentBranch)" -Arguments $args
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function grbs { Invoke-WriteExecCmd -Command 'git rebase --skip' -Arguments $args }
function gr { Invoke-WriteExecCmd -Command 'git reset' -Arguments $args }
function grh { Invoke-WriteExecCmd -Command 'git reset --hard' -Arguments $args }
function grho {
    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCmd -Command "git fetch --tags --prune --prune-tags --force $remote" -Parameters $args
        Invoke-WriteExecCmd -Command "git reset --hard $remote/$(Get-GitCurrentBranch)" -Parameters $args
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function grs { Invoke-WriteExecCmd -Command 'git reset --soft' -Arguments $args }
function grl { Invoke-WriteExecCmd -Command 'git reflog' -Arguments $args }
function grmc { Invoke-WriteExecCmd -Command 'git rm --cached' -Arguments $args }
function grm! { Invoke-WriteExecCmd -Command 'git rm --force' -Arguments $args }
function grmrc { Invoke-WriteExecCmd -Command 'git rm -r --cached' -Arguments $args }
function grmr! { Invoke-WriteExecCmd -Command 'git rm -r --force' -Arguments $args }
function grr { Invoke-WriteExecCmd -Command 'git restore' -Arguments $args }
function grp { Invoke-WriteExecCmd -Command 'git rev-parse' -Arguments $args }
function grrs { Invoke-WriteExecCmd -Command 'git restore --source' -Arguments $args }
function grt { Invoke-WriteExecCmd -Command 'git remote' -Arguments $args }
function grta { Invoke-WriteExecCmd -Command 'git remote add' -Arguments $args }
function grtrm { Invoke-WriteExecCmd -Command 'git remote remove' -Arguments $args }
function grtrn { Invoke-WriteExecCmd -Command 'git remote rename' -Arguments $args }
function grtsu { Invoke-WriteExecCmd -Command 'git remote set-url' -Arguments $args }
function grtup {
    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCmd -Command "git remote update $remote" -Arguments $args
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function grtupp {
    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCmd -Command "git remote update $remote --prune" -Arguments $args
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function grtv { Invoke-WriteExecCmd -Command 'git remote --verbose' -Arguments $args }
function gswc { Invoke-WriteExecCmd -Command 'git switch --create' -Arguments $args }
function gswd { Invoke-WriteExecCmd -Command 'git switch --detach' -Arguments $args }
function gswo { Invoke-WriteExecCmd -Command 'git switch --orphan' -Arguments $args }
function gsmi { Invoke-WriteExecCmd -Command 'git submodule init' -Arguments $args }
function gsmu { Invoke-WriteExecCmd -Command 'git submodule update' -Arguments $args }
function gsps { Invoke-WriteExecCmd -Command 'git show --pretty=short --show-signature' -Arguments $args }
function gsta { Invoke-WriteExecCmd -Command 'git stash push' -Arguments $args }
function gstaa { Invoke-WriteExecCmd -Command 'git stash push --all' -Arguments $args }
function gstac { Invoke-WriteExecCmd -Command 'git stash clear' -Arguments $args }
function gstal { Invoke-WriteExecCmd -Command 'git stash list' -Arguments $args }
function gstap { Invoke-WriteExecCmd -Command 'git stash pop' -Arguments $args }
function gst { Invoke-WriteExecCmd -Command 'git status' -Arguments $args }
function gstb { Invoke-WriteExecCmd -Command 'git status --short --branch' -Arguments $args }
function gsts { Invoke-WriteExecCmd -Command 'git status --short' -Arguments $args }
function gsvnd { Invoke-WriteExecCmd -Command 'git svn dcommit' -Arguments $args }
function gsvnr { Invoke-WriteExecCmd -Command 'git svn rebase' -Arguments $args }
function gt { Invoke-WriteExecCmd -Command 'git tag --sort=-v:refname' -Arguments $args }
function gts { Invoke-WriteExecCmd -Command 'git tag --sign' -Arguments $args }
function gtr { Invoke-WriteExecCmd -Command "git for-each-ref refs/tags/ --sort=-v:refname --format='%1B[33m%(objectname:short)%1B[m %1B[31m%(refname:short)%1B[m %(subject) %1B[1;94m%(authorname)%1B[m %1B[36m%(authoremail)%1B[m'" -Arguments @($args, '-Quiet') }
function gunignore { Invoke-WriteExecCmd -Command 'git update-index --no-assume-unchanged' -Arguments $args }
function gwch { Invoke-WriteExecCmd -Command 'git whatchanged -p --abbrev-commit --pretty=medium' -Arguments $args }
