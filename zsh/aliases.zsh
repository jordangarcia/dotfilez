alias reload!='. ~/.config/zsh/.zshrc'

# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if which exa &>/dev/null
then
  alias ls="exa"
  alias l="exa -l -a --group-directories-first --icons"
else
  alias ls="ls"
  alias l="ls -lah"
fi


alias vim='nvim'
alias vi='nvim'

# vim with no session
alias newvi='DISABLE_AUTO_SESSION=1 nvim'

# vim with no plugins
alias vinalla='nvim -u NONE'
alias vimilla='nvim -u NONE'
alias vinilla='nvim -u NONE'

# most recent 10 git branches accessed
alias gbl='git checkout $(git branch --sort=-committerdate | head -n 20 | fzf)'
alias gblast='for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k|head -n 1`\\t$k;done|sort -r | head -n 10'
alias gbl1='gblast|perl -pe s/(?:.+)\\t// | grep -v "^main$" | grep -v "`git rev-parse --abbrev-ref HEAD`" | head -n 1'
alias gcol='git checkout `gbl1`'
# The oldest 10 branches last accessed
alias gblr='for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k|head -n 1`\\t$k;done|sort | head -n 10'
#git branch -d
alias gbd='git branch -d'

# organizational things
alias i18n='yarn i18n:en'
alias gcoi18n='git checkout main -- $(git rev-parse --show-toplevel)/packages/client/src/translations/en/messages.po'


# Changing/making/removing directory
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

alias -- -='cd -'

# List directory contents

# GIT STUFF
alias gl='git pull --prune'
alias glo='gl && git pull origin'
alias glr='git pull --rebase'
alias glg="git log --graph --pretty=format:'%Cred%h%Creset %Cblue%an%Creset: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias glg2='if [ $(tput cols) -gt 120 ]; then \
    git log --graph --pretty=format:"%Cred%h%Creset %Cblue%an%Creset: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset" --abbrev-commit --date=relative | \
    fzf --ansi --no-sort --preview "echo {} | cut -d\" \" -f2 | xargs git show --color=always"; \
  else \
    git log --graph --pretty=format:"%Cred%h%Creset %Cblue%an%Creset: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset" --abbrev-commit --date=relative | \
    fzf --ansi --no-sort; \
  fi | cut -d" " -f2'

alias grbi='glg2 | xargs -I {} git rebase -i {}'
alias gp='git push -u origin HEAD'
alias glrp='glr && gp'
alias gd='git diff'
alias gdc='git diff --cached'
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git commit --amend'
alias gcp='git cherry-pick'
alias gb='git branch'
alias gs='git status -sb' # upgrade your git if -sb breaks for you. it's fun.
alias grm="git status | grep deleted | awk '{print \$3}' | xargs git rm"
alias gstash='git stash -u'

alias gamma="kitty --session ~/.config/kitty/sessions/gamma.conf &"
alias lvim="NVIM_APPNAME=lazyvim nvim"
alias myprs="gh pr list --author=@me | fzf | awk '{print $1}' | xargs -I {} gh pr view {} --web"
alias prs="gh pr list | fzf | awk '{print $1}' | xargs -I {} gh pr view {} --web"

alias ask="GITHUB_TOKEN='' gh copilot suggest -t shell"
alias copilot="GITHUB_TOKEN='' gh copilot suggest "

alias lastcommit="git log --pretty=format:'%h' -n 1"
alias lzd="lazydocker"
alias vienvrc="vi ~/code/gamma/.envrc && direnv allow"
alias vienvrclocal="vi ~/code/gamma/.envrc.local && direnv allow"

alias pbq="pbpaste | jq"
alias pbhtml="pbpaste | prettier --parser html"
