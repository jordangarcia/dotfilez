# handles all node / nvm setup
export PATH="/Users/jordan/.nvm/versions/node/v10.13.0/bin:$PATH"

lazynvm() {
  unset -f nvm
  export NVM_DIR=~/.nvm
  . "$(brew --prefix nvm)/nvm.sh"
  #[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
}

nvm() {
  lazynvm
  nvm $@
}

autoload -U add-zsh-hook
load-nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use
  fi
}

add-zsh-hook chpwd load-nvmrc
