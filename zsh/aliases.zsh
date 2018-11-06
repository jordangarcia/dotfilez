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

alias cdjs="cd ~/code/optimizely/src/www/frontend/assets/js/"
alias cdf="cd ~/code/optimizely/src/www/frontend/"
alias cdo="cd ~/code/optimizely/src/www/frontend/src/js/optly"
alias cdp13n="cd ~/code/optimizely/src/www/frontend/src/js/bundles/p13n"

alias vim='TERM=xterm-256color vim'
alias vi='vim'
alias tmux='TERM=screen-256color-bce tmux'
alias gulpbundle='cd ~/code/watcher && OPTIMIZELY_DIR=~/code/optimizely JS_BUILD_ARGS="-b bundle -c raw" gulp'
alias gulptest='cd ~/code/watcher && OPTIMIZELY_DIR=~/code/optimizely JS_BUILD_ARGS="-b bundle bundle_jstest -c raw" gulp'
alias gulpdashboard='cd ~/code/watcher && OPTIMIZELY_DIR=~/code/optimizely JS_BUILD_ARGS="-b bundle dashboard_tests dashboard_jstest -c raw" gulp'
# most recent 10 git branches accessed
alias gbl='for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k|head -n 1`\\t$k;done|sort -r | head -n 10'
alias gbl1='gbl|perl -pe s/(?:.+)\\t// | grep -v "^devel$" | grep -v "`git rev-parse --abbrev-ref HEAD`" | head -n 1'
alias gcol='git checkout `gbl1`'
# The oldest 10 branches last accessed
alias gblr='for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k|head -n 1`\\t$k;done|sort | head -n 10'
#git branch -d
alias gbd='git branch -d'
alias nw="/Applications/nwjs.app/Contents/MacOS/nwjs"

# organizational things
alias backlog='vi ~/code/jordans-backlog/README.md'
alias pushbacklog='pushd >> /dev/null 2>&1 && cd ~/code/jordans-backlog/ && git add . && git commit -m "update" && git push && popd >> /dev/null 2>&1'

alias evaldocker='eval $(docker-machine env default)'
alias dockersaml='docker run -d --name=aws_cred_server -v $HOME/.aws:/app/.aws -p 2700:2700 --restart=always quay.io/optimizely/aws-cred-server:latest'

alias cbdd='cd ~/code/optimizely/src/www/test/bdd'

alias gdf='vim `{git diff origin/devel... --name-only --relative -- "*.js"; git diff --name-only --relative -- "*.js"} | cat | fzf`'

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

