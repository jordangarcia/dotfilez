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

alias gdf='vim `git diff origin/devel... --name-only --relative -- "*.js" | fzf`'

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


# PAngaea shortcuts
alias mysql='mysql -uroot -ppassword'

alias sshfactorio="ssh root@134.122.127.246"
alias envprod="rm .env && ln -s ../.env-prod ./.env"
alias envlocal="rm .env && ln -s ../.env-local ./.env"
alias envstaging="rm .env && ln -s ../.env-staging ./.env"
alias sshprod1="ssh ubuntu@52.9.8.149"
alias sshprod2="ssh ubuntu@54.183.105.11"
alias sshstaging="ssh -i ~/.ssh/id_menskin ubuntu@54.153.11.224"
alias sshqueueworker="ssh -i ~/.ssh/id_menskin ubuntu@52.8.90.224"

alias pangaea-free-trial="curl --location --request POST 'http://app.luminskin.local/api/checkout' --header 'content-type: application/x-www-form-urlencoded; charset=UTF-8' --header 'Cookie: XSRF-TOKEN=eyJpdiI6IldPMzZrQnhCZU0zWmdSN3JuN2dLbHc9PSIsInZhbHVlIjoiN1wvbnRkeHBEZVNcL3dqbWVnVkdnNlFFaWpkWit0d3JFVVg2cGVnZVhtTTh6T01hSjNLdkVJbit4SDhxSWdSMnNZIiwibWFjIjoiOTc4M2Y1OWQ4ZDY1ZGE3Y2I3NzZlYzcxMTc5YjU0MGMzNmJlY2RiM2E1Y2VjMTQ2YmI5ZjJhMzcxZTNlYjBkYSJ9; local_session=eyJpdiI6IkJTSVpQSkNJM2ZpcXhQd1d2MkI2bmc9PSIsInZhbHVlIjoiYVdlRVlRNVYyVlwvTFArSE1mZW1iVUpnNEdGRjlSQWl6SzBNS1BId2Y4U01OSG1kSHBna2FmdGNEMFwvUThsaThVIiwibWFjIjoiMzBmZmNiODU2YzY1MTIwZDE5ZDBmN2EyNzQ1MmI4NzRmMzQxZGEzY2U1NzYyMDE4NDViNTdlZTkzYjZiZmVjMiJ9' --data-raw 'currency=USD&coupon=FREE_TRIAL&products%5B0%5D%5Blabel_display_text%5D=jordan+garcia&products%5B0%5D%5Bproduct_option_value_ids%5D%5B%5D=48&products%5B0%5D%5Bproduct_option_value_ids%5D%5B%5D=51&products%5B0%5D%5Bproduct_option_value_ids%5D%5B%5D=56&products%5B0%5D%5Bquantity%5D=1&products%5B0%5D%5Binterval%5D=2month' | jq '.data[0].cart_url' | xargs open"

