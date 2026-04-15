# set XDG_* paths
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

unsetopt nomatch
# export TERM=wezterm
export PATH=/opt/homebrew/bin:$PATH

# your project folder that we can `c [tab]` to
export PROJECTS=~/code
export GAMMA=$PROJECTS/gamma

export EDITOR=nvim

# all of our zsh files
typeset -U config_files
config_files=($XDG_CONFIG_HOME/zsh/**/*.zsh)

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

# WezTerm shell integration
if [[ $TERM_PROGRAM == "WezTerm" ]]; then
  source ~/code/dotfilez/zsh/wezterm.sh 2>/dev/null || true
fi

# Kitty shell integration
if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# gmx worktree manager
gmx() {
    case "${1:-}" in
        @)
            for _gmx_arg in "${@:2}"; do
                [[ "$_gmx_arg" == "--help" || "$_gmx_arg" == "-h" ]] && {
                    printf 'Usage: gmx @ [PATTERN]\n\nChange directory to a matching worktree.\nWith no PATTERN, opens interactive fuzzy selection.\n'
                    return 0
                }
            done
            local dir
            if [[ $# -le 1 ]]; then
                dir=$(command gmx filter) || return $?
            else
                dir=$(command gmx list --path "${@:2}" 2>/dev/null | head -1) || return $?
            fi
            [[ -n "$dir" ]] || { echo >&2 "gmx: @: no worktree found"; return 1; }
            cd "$dir" || return $?
            ;;
        create | c)
            for _gmx_arg in "${@:2}"; do
                [[ "$_gmx_arg" == "--help" || "$_gmx_arg" == "-h" ]] && {
                    command gmx "$@"
                    return $?
                }
            done
            local dir
            dir=$(command gmx "$@") || return $?
            cd "$dir" || return $?
            ;;
        *)
            command gmx "$@"
            ;;
    esac
}

# gmx shell completions
eval "$(COMPLETE=zsh command gmx)"
