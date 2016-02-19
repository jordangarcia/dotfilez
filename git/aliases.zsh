alias gl='git pull --prune'
alias glo='gl && git pull origin'
alias glr='git pull --rebase'
alias glg="git log --graph --pretty=format:'%Cred%h%Creset %Cblue%an%Creset: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp='git push -u origin HEAD'
alias glrp='glr && gp'
alias gph='git push heroku HEAD'
alias gd='git diff'
alias gdc='git diff --cached'
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git commit --amend'
alias gco='git checkout'
alias gb='git branch'
alias gs='git status -sb' # upgrade your git if -sb breaks for you. it's fun.
alias grm="git status | grep deleted | awk '{print \$3}' | xargs git rm"
alias gdt='git dt'
alias gstash='git stash -u'
