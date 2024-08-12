export PYENV_ROOT="$HOME/.pyenv"

export PYENV_VERSION="3.12.4"

# the follow command runs:
#
# PATH="$(bash --norc -ec 'IFS=:; paths=($PATH);
# for i in ${!paths[@]}; do
# if [[ ${paths[i]} == "''/Users/jordan/.pyenv/shims''" ]]; then unset '\''paths[i]'\'';
# fi; done;
# echo "${paths[*]}"')"
# export PATH="/Users/jordan/.pyenv/shims:${PATH}"
# export PYENV_SHELL=zsh
# source '/opt/homebrew/Cellar/pyenv/2.4.8/libexec/../completions/pyenv.zsh'
# command pyenv rehash 2>/dev/null
# pyenv() {
#   local command
#   command="${1:-}"
#   if [ "$#" -gt 0 ]; then
#     shift
#   fi
#
#   case "$command" in
#   rehash|shell)
#     eval "$(pyenv "sh-$command" "$@")"
#     ;;
#   *)
#     command pyenv "$command" "$@"
#     ;;
#   esac
# }
#
# Setups up pyenv
# adds shims to path which point to python
eval "$(pyenv init -)"
