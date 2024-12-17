unsetopt nomatch
# export TERM=wezterm
export PATH=/opt/homebrew/bin:$PATH

# shortcut to this dotfiles path is $ZSH
export ZSH=$HOME/.dotfiles

# your project folder that we can `c [tab]` to
export PROJECTS=~/code
export GAMMA=$PROJECTS/gamma

export EDITOR=vim
export OPTIMIZELY=$PROJECTS/optimizely

# all of our zsh files
typeset -U config_files
config_files=($ZSH/zsh/**/*.zsh)

# load the path files
for file in ${(M)config_files:#*/path.zsh}
do
  source $file
done

# dont load path, completion or zshrc
for file in ${${${${config_files:#*/path.zsh}:#*/completion.zsh}:#*/zshrc.zsh}:#*/plugins.zsh}
do
  source $file
done

if [[ -z "$HOMEBREW_PREFIX" ]]; then
  # Maintain compatability with potential custom user profiles, where we had
  # previously relied on always sourcing shellenv. OMZ plugins should not rely
  # on this to be defined due to out of order processing.
  export HOMEBREW_PREFIX="$(brew --prefix)"
fi

if [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath+=("$HOMEBREW_PREFIX/share/zsh/site-functions")
fi

# Clone antidote if necessary.
[[ -d ${ZDOTDIR:-~}/.antidote ]] ||
  git clone https://github.com/mattmc3/antidote ${ZDOTDIR:-~}/.antidote

# Create an amazing Zsh config using antidote plugins.
source ${ZDOTDIR:-~}/.antidote/antidote.zsh
antidote load

# initialize autocomplete here, otherwise functions won't be loaded
autoload -Uz compinit && compinit

# load every completion after autocomplete loads
for file in ${(M)config_files:#*/completion.zsh}
do
  source $file
done

unset config_files


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jordan/code/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/jordan/code/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jordan/code/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/jordan/code/google-cloud-sdk/completion.zsh.inc'; fi

# fix JQ colors
export JQ_COLORS="1;33:0;37:0;37:0;37:0;32:1;37:1;37:1;33"

# bun completions
[ -s "/Users/jordan/.bun/_bun" ] && source "/Users/jordan/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# fix node shit
export NODE_TLS_REJECT_UNAUTHORIZED=1

