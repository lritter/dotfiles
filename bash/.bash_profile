# Try and discover where *this file* lives.  This is a bit annoying and probably not very
# reliable since normally I symlink it. It's possilble a better alternative is to just
# assume that it lives at ~/.bash_profile and go from there...
CONFIG_DIR=$(dirname $(readlink "${BASH_SOURCE[0]}"))
if [ -d "$CONFIG_DIR" ]; then
  export BASH_CONFIG_ROOT="$(dirname $(readlink "${BASH_SOURCE[0]}"))"
else
  export BASH_CONFIG_ROOT="/Users/$(whoami)/$(dirname $(readlink "${BASH_SOURCE[0]}"))"
fi
# export BASH_CONFIG_ROOT="$( dirname $( readlink "${BASH_SOURCE[0]}" ))"
source "$BASH_CONFIG_ROOT"/bash_env

if [ -f /etc/bashrc ]; then
  . /etc/bashrc # --> Read /etc/bashrc, if present.
fi

[[ $- = *i* ]] || return

shopt -s histappend # Append to history file instead of overwrite

# Try to load up some completions
for file in /usr/local/etc/bash_completion.d/{git-completion.bash,git-prompt.sh,R}; do
  [ -r "$file" ] && source "$file"
done
unset file

# bash_colors.sh,

for file in "$BASH_CONFIG_ROOT"/{findmyfile.function,__edit.function,exitstatus_prompt.function,copy.function,history,completion,aliases,misc_functions.function,google-cloud-sdk.sh,nvm.sh,spec_for.sh,rbenv.sh,git_switch.sh}; do
  [ -r "$file" ] && source "$file"
done
unset file

# ASDF
# . $(brew --prefix asdf)/asdf.sh

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
  shopt -s "$option" 2>/dev/null
done

# Make bash check its window size after a process completes
shopt -s checkwinsize

# source "$BASH_CONFIG_ROOT"/liquidprompt/liquidprompt
export CONFIG_ENV=development
export RACK_ENV=development
export RAILS_ENV=development

source "$BASH_CONFIG_ROOT"/setup_ssh.sh

source "$BASH_CONFIG_ROOT"/firehydrant.sh
ulimit -n 10240

bracketed-paste-disable

# eval "$(pyenv init -)"
# eval "$(direnv hook bash)"

cdnvm() {
  command cd "$@" || return $?
  nvm_path="$(nvm_find_up .nvmrc | command tr -d '\n')"

  # If there are no .nvmrc file, use the default nvm version
  if [[ ! $nvm_path = *[^[:space:]]* ]]; then

    declare default_version
    default_version="$(nvm version default)"

    # If there is no default version, set it to `node`
    # This will use the latest version on your machine
    if [ $default_version = 'N/A' ]; then
      nvm alias default node
      default_version=$(nvm version default)
    fi

    # If the current version is not the default version, set it to use the default version
    if [ "$(nvm current)" != "${default_version}" ]; then
      nvm use default
    fi
  elif [[ -s "${nvm_path}/.nvmrc" && -r "${nvm_path}/.nvmrc" ]]; then
    declare nvm_version
    nvm_version=$(<"${nvm_path}"/.nvmrc)

    declare locally_resolved_nvm_version
    # `nvm ls` will check all locally-available versions
    # If there are multiple matching versions, take the latest one
    # Remove the `->` and `*` characters and spaces
    # `locally_resolved_nvm_version` will be `N/A` if no local versions are found
    locally_resolved_nvm_version=$(nvm ls --no-colors "${nvm_version}" | command tail -1 | command tr -d '\->*' | command tr -d '[:space:]')

    # If it is not already installed, install it
    # `nvm install` will implicitly use the newly-installed version
    if [ "${locally_resolved_nvm_version}" = 'N/A' ]; then
      nvm install "${nvm_version}"
    elif [ "$(nvm current)" != "${locally_resolved_nvm_version}" ]; then
      nvm use "${nvm_version}"
    fi
  fi
}

alias cd='cdnvm'
cdnvm "$PWD" || exit

# If this is not an interactive shell, don't do anything
[[ $- = *i* ]] || return

function set_win_title() {
  echo -ne "\033]0;$(basename "$PWD")\007"
}

starship_precmd_user_func="set_win_title"

eval "$(starship init bash)"
# if [ -f /opt/homebrew/share/liquidprompt ]; then
#   . /opt/homebrew/share/liquidprompt
# fi

eval "$(direnv hook bash)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
  eval "$__conda_setup"
else
  if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
    . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
  else
    export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
  fi
fi
unset __conda_setup
# <<< conda initialize <<<
