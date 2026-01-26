# fnm (fast node manager) - replaces nvm
eval "$(fnm env --use-on-cd)"

# keep nvm command available for edge cases (lazy-loaded)
nvm() {
  unset -f nvm
  export NVM_DIR=~/.nvm
  . "$(brew --prefix nvm)/nvm.sh"
  nvm $@
}
