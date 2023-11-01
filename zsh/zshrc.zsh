unsetopt nomatch
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
for file in ${${${config_files:#*/path.zsh}:#*/completion.zsh}:#*/zshrc.zsh}
do
  source $file
done

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


eval "$(direnv hook zsh)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jordan/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/jordan/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jordan/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/jordan/google-cloud-sdk/completion.zsh.inc'; fi

# source /Users/jordan/.dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(zoxide init zsh)"
