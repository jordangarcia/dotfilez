alias reload!='. ~/.zshrc'

# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if which gls &>/dev/null
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -A --color'
else
  alias ls="ls"
  alias l="ls -al"
  alias ll="ls -l"
fi


alias vim='TERM=xterm-256color vim'
alias vi='vim'
alias tmux='TERM=screen-256color-bce tmux'
# most recent 10 git branches accessed
alias gbl='for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k|head -n 1`\\t$k;done|sort -r | head -n 10'
alias gbl1='gbl|perl -pe s/(?:.+)\\t// | grep -v "^main$" | grep -v "`git rev-parse --abbrev-ref HEAD`" | head -n 1'
alias gcol='git checkout `gbl1`'
# The oldest 10 branches last accessed
alias gblr='for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k|head -n 1`\\t$k;done|sort | head -n 10'
#git branch -d
alias gbd='git branch -d'
alias nw="/Applications/nwjs.app/Contents/MacOS/nwjs"

# organizational things
alias evaldocker='eval $(docker-machine env default)'

alias i18n='yarn i18n:en'
alias gcoi18n='git checkout main -- $(git rev-parse --show-toplevel)/packages/client/src/translations/en/messages.po'


# Changing/making/removing directory
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias -- -='cd -'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

alias md='mkdir -p'
alias rd=rmdir
alias d='dirs -v | head -10'

# List directory contents
alias lsa='ls -lah'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'
